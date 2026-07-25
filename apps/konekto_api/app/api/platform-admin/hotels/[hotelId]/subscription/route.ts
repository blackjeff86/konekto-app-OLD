import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const subscriptionSchema = z.object({
  planName: z.string().trim().min(1),
  monthlyAmount: z.number().nonnegative().nullable().optional(),
  status: z.enum(['active', 'trial', 'suspended', 'cancelled']),
  paymentStatus: z.enum(['em_dia', 'atrasado', 'isento']),
  notes: z.string().trim().max(2000).nullable().optional(),
  // Categoria White Label (controla template/feature flag do app do
  // hóspede — ver lib/feature-flags.ts). Opcional aqui só pra não quebrar
  // chamadas antigas do konekto_admin que ainda não mandam esse campo; ao
  // criar (`create`), o `@default(essential)` do Prisma cobre a ausência.
  plan: z.enum(['essential', 'premium', 'enterprise']).optional(),
})

// Upsert do plano/assinatura do hotel — quem seta isso é sempre o time do
// Konekto pelo `konekto_admin`, nunca o hotel. "Status do pagamento" nesta
// v1 é um campo manual (sem fatura/boleto real ainda, isso é fase 2).
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = subscriptionSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const { planName, monthlyAmount, status, paymentStatus, notes, plan } = parsed.data
  const subscription = await prisma.hotelSubscription.upsert({
    where: { hotelId },
    create: { hotelId, planName, monthlyAmount, status, paymentStatus, notes, plan },
    update: { planName, monthlyAmount, status, paymentStatus, notes, plan },
  })

  return NextResponse.json(subscription)
}
