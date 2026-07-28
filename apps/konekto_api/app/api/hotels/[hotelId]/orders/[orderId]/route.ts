import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { notifyRestaurantReservationCancelled, notifyRestaurantReservationConfirmed } from '@/lib/basic-notifications'
import {
  notifyRoomServiceOrderAccepted,
  notifyRoomServiceOrderCancelled,
  notifyRoomServiceOrderCompleted,
} from '@/lib/basic-notifications'

export const runtime = 'nodejs'

const patchOrderSchema = z.object({
  status: z.enum(['pending', 'in_progress', 'completed', 'cancelled']),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; orderId: string }> },
) {
  const { hotelId, orderId } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente', 'recepcao'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const parsed = patchOrderSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.order.findUnique({ where: { id: orderId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'order_not_found' }, { status: 404 })
  }

  // A recepção mudou o status — o hóspede ainda não viu essa mudança, então
  // volta a contar no sino de notificações até ele abrir "Meus Pedidos".
  const updated = await prisma.order.update({
    where: { id: orderId },
    data: { status: parsed.data.status, statusSeenByGuest: false },
  })

  const isRoomServiceOrder = existing.scheduledFor == null && existing.itemName !== 'Reserva de mesa'
  if (isRoomServiceOrder) {
    if (parsed.data.status === 'in_progress') {
      await notifyRoomServiceOrderAccepted({
        hotelId,
        guestId: existing.guestId,
        orderId: existing.id,
        itemName: existing.itemName,
      })
    }

    if (parsed.data.status === 'completed') {
      await notifyRoomServiceOrderCompleted({
        hotelId,
        guestId: existing.guestId,
        orderId: existing.id,
        itemName: existing.itemName,
      })
    }

    if (parsed.data.status === 'cancelled') {
      await notifyRoomServiceOrderCancelled({
        hotelId,
        guestId: existing.guestId,
        orderId: existing.id,
        itemName: existing.itemName,
      })
    }
  }

  if (existing.scheduledFor && (existing.tableTypeId != null || existing.itemName === 'Reserva de mesa')) {
    if (parsed.data.status === 'in_progress') {
      await notifyRestaurantReservationConfirmed({
        hotelId,
        guestId: existing.guestId,
        reservationId: existing.id,
        scheduledFor: existing.scheduledFor,
      })
    }

    if (parsed.data.status === 'cancelled') {
      await notifyRestaurantReservationCancelled({
        hotelId,
        guestId: existing.guestId,
        reservationId: existing.id,
        scheduledFor: existing.scheduledFor,
        reason: 'cancelled',
      })
    }
  }

  return NextResponse.json(updated)
}
