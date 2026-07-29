import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import type { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { verifyStaffToken } from '@/lib/jwt'
import { autoTranslateOrNull } from '@/lib/translate'
import { validateOperatingHoursFields } from '@/lib/scheduling'
import { isModuleId } from '@/lib/module-catalog'
import { resolveHotelAllowedModuleIds, resolveHotelEnabledModuleIds } from '@/lib/service-module-gate'

export const runtime = 'nodejs'

// Rota pública (app do hóspede não manda token): por padrão só devolve
// serviços habilitados. Se vier um Bearer token válido de gerente do mesmo
// hotel, também inclui os desabilitados — é assim que o portal consegue
// listar (e reabilitar) um serviço que ele mesmo desligou.
async function isGerenteOfHotel(request: NextRequest, hotelId: string): Promise<boolean> {
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) return false
  try {
    const payload = await verifyStaffToken(token)
    return payload.role === 'gerente' && payload.hotelId === hotelId
  } catch {
    return false
  }
}

// Módulo desligado esconde o serviço mesmo com `enabled: true` — só pro
// hóspede (gerente do próprio hotel continua vendo tudo, pra conseguir
// religar o módulo ou reatribuir o serviço). `moduleId: null` (dado de
// antes da Fase 12, ainda não revisado manualmente) nunca é escondido.
export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const isGerente = await isGerenteOfHotel(request, hotelId)
  const services = await prisma.service.findMany({
    where: isGerente ? { hotelId } : { hotelId, enabled: true },
    orderBy: { position: 'asc' },
  })
  if (isGerente) {
    return NextResponse.json(services)
  }
  const enabledModuleIds = await resolveHotelEnabledModuleIds(hotelId)
  const visible = services.filter((service) => service.moduleId == null || enabledModuleIds.has(service.moduleId))
  return NextResponse.json(visible)
}

const createServiceSchema = z
  .object({
    name: z.string().min(1),
    slug: z.string().min(1),
    icon: z.string().min(1),
    description: z.string(),
    type: z.enum(['room_service', 'restaurant', 'activity']),
    category: z.string().trim().min(1),
    // Módulo de Hospitalidade — obrigatório em todo Service criado a
    // partir da Fase 12 (dado de antes dela é nullable, ver schema.prisma).
    // Validado abaixo contra o que o plano do hotel de fato permite, não
    // só contra a lista de ids conhecidos.
    moduleId: z.string().trim().min(1).refine(isModuleId, { message: 'unknown_module' }),
    bannerImageUrl: z.string().min(1).optional(),
    operatingDaysOfWeek: z.array(z.number().int().min(1).max(7)).optional(),
    operatingStartMinute: z.number().int().min(0).max(1439).nullable().optional(),
    operatingEndMinute: z.number().int().min(0).max(1439).nullable().optional(),
  })
  .superRefine((data, ctx) => {
    const result = validateOperatingHoursFields(data)
    if (!result.ok) {
      ctx.addIssue({ code: 'custom', message: result.error })
    }
  })

export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const parsed = createServiceSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const allowedModuleIds = await resolveHotelAllowedModuleIds(hotelId)
  if (!allowedModuleIds.has(parsed.data.moduleId)) {
    return NextResponse.json({ error: 'module_not_allowed_for_plan' }, { status: 403 })
  }

  const existing = await prisma.service.findUnique({
    where: { hotelId_slug: { hotelId, slug: parsed.data.slug } },
  })
  if (existing) {
    return NextResponse.json({ error: 'slug_already_exists' }, { status: 409 })
  }

  const maxPosition = await prisma.service.aggregate({
    where: { hotelId },
    _max: { position: true },
  })
  const nextPosition = (maxPosition._max.position ?? -1) + 1

  const translations = await autoTranslateOrNull({ name: parsed.data.name, description: parsed.data.description })

  const service = await prisma.service.create({
    data: { hotelId, position: nextPosition, ...parsed.data, translations: (translations ?? undefined) as Prisma.InputJsonValue | undefined },
  })
  return NextResponse.json(service, { status: 201 })
}
