import { randomUUID } from 'crypto'
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import type { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'
import { buildHotelOverview } from '@/lib/platform-admin-hotel-shape'
import { generateTemporaryPassword } from '@/lib/generate-temporary-password'
import { recordPlatformAdminAudit } from '@/lib/platform-admin-audit'

export const runtime = 'nodejs'

// Lista todos os hotéis clientes da plataforma — visão administrativa
// cross-tenant (nome/endereço, plano/assinatura, hóspedes ativos agora,
// saúde de integração, mensagens de suporte não lidas). Só o time da
// Sevvn acessa isso (`requirePlatformAdmin`).
//
// `kind: 'client'` exclui qualquer hotel `template` (hoje não existe
// nenhum — os 5 templates White Label não dependem de hotel no banco, ver
// legacy-templates/README.md em konekto_mobile) — mantido como filtro de
// segurança pra nunca contar um hotel não-cliente nos KPIs de
// Dashboard/Financeiro (que reaproveitam esta mesma lista).
export async function GET(request: NextRequest) {
  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const hotels = await prisma.hotel.findMany({ where: { kind: 'client' }, orderBy: { createdAt: 'asc' } })
  const overviews = await Promise.all(hotels.map((hotel) => buildHotelOverview(hotel)))
  return NextResponse.json(overviews)
}

const createHotelSchema = z.object({
  name: z.string().trim().min(1),
  // Categoria White Label do hotel — default `essential` (o mais
  // restrito) quando omitido, nunca assume um plano pago sem intenção
  // explícita de quem está criando o hotel.
  plan: z.enum(['essential', 'premium', 'enterprise']).default('essential'),
  gerente: z.object({
    name: z.string().trim().min(1),
    email: z.string().trim().toLowerCase().email(),
  }),
})

// Onboarding de um cliente real — antes disso, a ÚNICA forma de um Hotel
// existir era `prisma/seed.ts`, travado nos dois IDs de template (Verde
// Pousada/Amara Bay). Isso já causou um incidente real: o primeiro cliente
// foi cadastrado renomeando um hotel template diretamente, e um re-seed
// apagou esse nome de volta duas vezes (ver trava em `seed.ts`). Esta rota
// cria um `Hotel` com ID novo (nunca reaproveita um template) e já cria o
// primeiro `Staff` (gerente) junto — sem isso o hotel nasceria sem
// ninguém com acesso ao portal (o `StaffInvite` existente não serve pra
// isso: trava `role` em `recepcao` e exige um gerente JÁ autenticado pra
// gerar o convite, circular pra um hotel zerado).
export async function POST(request: NextRequest) {
  let admin
  try {
    admin = await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = createHotelSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existingStaff = await prisma.staff.findUnique({ where: { email: parsed.data.gerente.email } })
  if (existingStaff) {
    return NextResponse.json({ error: 'email_already_in_use' }, { status: 409 })
  }

  const hotelId = randomUUID()
  const temporaryPassword = generateTemporaryPassword()
  const passwordHash = await bcrypt.hash(temporaryPassword, 10)

  // `hotelInfo` sempre em branco/placeholder. `template` é o único campo
  // que controla o visual do app do hóspede — todo hotel novo nasce em
  // `aura` (disponível em todos os planos, inclusive Essential) até a
  // equipe Sevvn ou o próprio hotel trocarem, no admin da plataforma ou
  // no portal.
  const config = {
    template: 'aura',
    hotelInfo: {
      name: parsed.data.name,
      logoUrl: null,
      address: null,
      promoImages: { carouselEnabled: false, images: [] as string[], carouselHeight: 220 },
    },
  }

  // Rótulo comercial (`planName`) começa igual ao nome do plano — é só o
  // default inicial, texto livre editável depois pela equipe Sevvn na
  // tela de assinatura (não existe formulário de nome de plano customizado
  // ainda no onboarding).
  const planNameByPlan: Record<typeof parsed.data.plan, string> = {
    essential: 'Essential',
    premium: 'Premium',
    enterprise: 'Enterprise',
  }

  await prisma.$transaction(async (tx) => {
    await tx.hotel.create({ data: { id: hotelId, config: config as unknown as Prisma.InputJsonValue } })
    await tx.staff.create({
      data: {
        hotelId,
        email: parsed.data.gerente.email,
        passwordHash,
        role: 'gerente',
        name: parsed.data.gerente.name,
      },
    })
    await tx.hotelSubscription.create({
      data: { hotelId, plan: parsed.data.plan, planName: planNameByPlan[parsed.data.plan], status: 'trial' },
    })
    await recordPlatformAdminAudit(tx, {
      action: 'platform_admin.hotel.created',
      admin,
      hotelId,
      payload: {
        gerenteEmail: parsed.data.gerente.email,
        gerenteName: parsed.data.gerente.name,
        hotelName: parsed.data.name,
        plan: parsed.data.plan,
      },
      request,
      targetId: hotelId,
      targetType: 'hotel',
    })
  })

  return NextResponse.json(
    { hotelId, gerente: { name: parsed.data.gerente.name, email: parsed.data.gerente.email }, temporaryPassword },
    { status: 201 },
  )
}
