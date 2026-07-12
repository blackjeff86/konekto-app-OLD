import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchOrderSchema = z
  .object({
    quantity: z.number().int().min(1).optional(),
    note: z.string().trim().max(500).nullable().optional(),
    scheduledFor: z.coerce.date().optional(),
    cancel: z.boolean().optional(),
  })
  .refine(
    (data) => data.cancel || data.quantity !== undefined || data.note !== undefined || data.scheduledFor !== undefined,
    { message: 'no_fields_to_update' },
  )

// Edição/cancelamento pelo PRÓPRIO hóspede — separado do
// `PATCH /api/hotels/:hotelId/orders/:orderId` do staff (que avança o
// status de preparo). Um hóspede só pode mexer no próprio pedido, e só
// enquanto ele ainda estiver `pending` (cozinha ainda não começou o
// preparo) — depois disso, quantidade/observação ficam travadas e cancelar
// não é mais permitido.
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ orderId: string }> }) {
  const { orderId } = await params

  let guest
  try {
    guest = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = patchOrderSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.order.findUnique({ where: { id: orderId } })
  if (!existing || existing.guestId !== guest.sub) {
    return NextResponse.json({ error: 'order_not_found' }, { status: 404 })
  }
  if (existing.status !== 'pending') {
    return NextResponse.json({ error: 'order_already_in_progress' }, { status: 409 })
  }
  // `price` já vem com o desconto do cupom embutido pra essa quantidade
  // específica — mudar a quantidade sem recalcular o cupom inteiro
  // (mínimo de pedido, limite de uso) deixaria o desconto errado. Mais
  // simples pedir pra cancelar e refazer o pedido nesse caso raro.
  if (existing.couponId && parsed.data.quantity !== undefined) {
    return NextResponse.json({ error: 'cannot_change_quantity_with_coupon' }, { status: 409 })
  }

  const data = parsed.data.cancel
    ? { status: 'cancelled' as const }
    : {
        ...(parsed.data.quantity !== undefined ? { quantity: parsed.data.quantity } : {}),
        ...(parsed.data.note !== undefined ? { note: parsed.data.note } : {}),
        ...(parsed.data.scheduledFor !== undefined ? { scheduledFor: parsed.data.scheduledFor } : {}),
      }

  const updated = await prisma.order.update({ where: { id: orderId }, data })
  return NextResponse.json(updated)
}
