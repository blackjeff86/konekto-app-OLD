import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import type { Order } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'
import { notifyRestaurantReservationCancelled, notifyRestaurantReservationRescheduled } from '@/lib/basic-notifications'
import { canonicalizeSlotStart, isBookableInstant, isValidScheduledSlot, isWithinOperatingHours } from '@/lib/scheduling'

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

  if (parsed.data.cancel) {
    const updated = await prisma.order.update({ where: { id: orderId }, data: { status: 'cancelled' as const } })
    if (existing.scheduledFor && (existing.tableTypeId != null || existing.itemName === 'Reserva de mesa')) {
      await notifyRestaurantReservationCancelled({
        hotelId: existing.hotelId,
        guestId: existing.guestId,
        reservationId: existing.id,
        scheduledFor: existing.scheduledFor,
        reason: 'cancelled',
      })
    }
    return NextResponse.json(updated)
  }

  // Reagendar (scheduledFor mudou) num item com agendamento configurado
  // precisa passar pela MESMA revalidação e checagem de capacidade que
  // `POST /api/orders` faz na criação — sem isso, o hóspede podia driblar
  // toda a proteção contra conflito/dupla marcação simplesmente editando um
  // pedido pendente pra outro horário.
  if (parsed.data.scheduledFor !== undefined) {
    const item = await prisma.serviceItem.findUnique({ where: { id: existing.serviceItemId } })
    if (item?.durationMinutes != null) {
      const validSlot = isValidScheduledSlot(
        {
          durationMinutes: item.durationMinutes,
          availableDaysOfWeek: item.availableDaysOfWeek,
          availabilityStartMinute: item.availabilityStartMinute!,
          availabilityEndMinute: item.availabilityEndMinute!,
        },
        parsed.data.scheduledFor,
      )
      if (!validSlot) {
        return NextResponse.json({ error: 'invalid_schedule' }, { status: 400 })
      }
      const canonicalScheduledFor = canonicalizeSlotStart(parsed.data.scheduledFor)
      const lockKey = `${item.id}:${canonicalScheduledFor.toISOString()}`

      type RescheduleResult = { kind: 'full' } | { kind: 'ok'; order: Order }
      const result = await prisma.$transaction<RescheduleResult>(async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${lockKey}))`

        const activeCount = await tx.order.count({
          where: {
            serviceItemId: item.id,
            scheduledFor: canonicalScheduledFor,
            status: { not: 'cancelled' },
            id: { not: orderId },
          },
        })
        if (activeCount >= item.capacityPerSlot!) {
          return { kind: 'full' }
        }

        const order = await tx.order.update({
          where: { id: orderId },
          data: {
            scheduledFor: canonicalScheduledFor,
            ...(parsed.data.quantity !== undefined ? { quantity: parsed.data.quantity } : {}),
            ...(parsed.data.note !== undefined ? { note: parsed.data.note } : {}),
          },
        })
        return { kind: 'ok', order }
      })

      if (result.kind === 'full') {
        return NextResponse.json({ error: 'slot_full' }, { status: 409 })
      }
      await notifyRestaurantReservationRescheduled({
        hotelId: existing.hotelId,
        guestId: existing.guestId,
        reservationId: existing.id,
        scheduledFor: canonicalScheduledFor,
      })
      return NextResponse.json(result.order)
    }

    // Reagendar uma reserva de mesa com tipo de mesa configurado (mesmo
    // racional acima, agora contra `RestaurantTableType.quantity`) — sem
    // isso, o hóspede driblaria a checagem de capacidade da mesa só editando
    // o pedido pendente pra outro horário, exatamente o mesmo tipo de
    // brecha já corrigida pro agendamento de item.
    if (existing.tableTypeId != null) {
      const tableType = await prisma.restaurantTableType.findUnique({
        where: { id: existing.tableTypeId },
        include: { service: true },
      })
      if (!tableType) {
        return NextResponse.json({ error: 'table_type_not_found' }, { status: 404 })
      }
      if (!isBookableInstant(parsed.data.scheduledFor)) {
        return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
      }
      if (!isWithinOperatingHours(tableType.service, parsed.data.scheduledFor)) {
        return NextResponse.json({ error: 'service_closed' }, { status: 400 })
      }
      const canonicalScheduledFor = canonicalizeSlotStart(parsed.data.scheduledFor)
      const lockKey = `table:${tableType.id}:${canonicalScheduledFor.toISOString()}`

      type TableRescheduleResult = { kind: 'full' } | { kind: 'ok'; order: Order }
      const result = await prisma.$transaction<TableRescheduleResult>(async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${lockKey}))`

        const activeCount = await tx.order.count({
          where: {
            tableTypeId: tableType.id,
            scheduledFor: canonicalScheduledFor,
            status: { not: 'cancelled' },
            id: { not: orderId },
          },
        })
        if (activeCount >= tableType.quantity) {
          return { kind: 'full' }
        }

        const order = await tx.order.update({
          where: { id: orderId },
          data: {
            scheduledFor: canonicalScheduledFor,
            ...(parsed.data.note !== undefined ? { note: parsed.data.note } : {}),
          },
        })
        return { kind: 'ok', order }
      })

      if (result.kind === 'full') {
        return NextResponse.json({ error: 'table_full' }, { status: 409 })
      }
      await notifyRestaurantReservationRescheduled({
        hotelId: existing.hotelId,
        guestId: existing.guestId,
        reservationId: existing.id,
        scheduledFor: canonicalScheduledFor,
      })
      return NextResponse.json(result.order)
    }

    // Reagendar uma reserva de mesa de restaurante SEM tipo de mesa
    // configurado ainda (`tableTypeId` null — restaurante que não cadastrou
    // `RestaurantTableType` nenhum) continua sem checagem de capacidade
    // (nada pra checar), mas precisa respeitar o mesmo horário de
    // funcionamento e bound de data que `POST /api/orders` já aplica
    // SEMPRE nessa branch, independente de o restaurante ter tipos de mesa
    // configurados — sem isso, reagendar burlaria as duas checagens.
    const service = await prisma.service.findUnique({ where: { id: existing.serviceId } })
    if (service?.type === 'restaurant') {
      if (!isBookableInstant(parsed.data.scheduledFor)) {
        return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
      }
      if (!isWithinOperatingHours(service, parsed.data.scheduledFor)) {
        return NextResponse.json({ error: 'service_closed' }, { status: 400 })
      }
      const canonicalScheduledFor = canonicalizeSlotStart(parsed.data.scheduledFor)
      const updated = await prisma.order.update({
        where: { id: orderId },
        data: {
          scheduledFor: canonicalScheduledFor,
          ...(parsed.data.note !== undefined ? { note: parsed.data.note } : {}),
        },
      })
      await notifyRestaurantReservationRescheduled({
        hotelId: existing.hotelId,
        guestId: existing.guestId,
        reservationId: existing.id,
        scheduledFor: canonicalScheduledFor,
      })
      return NextResponse.json(updated)
    }
  }

  const data = {
    ...(parsed.data.quantity !== undefined ? { quantity: parsed.data.quantity } : {}),
    ...(parsed.data.note !== undefined ? { note: parsed.data.note } : {}),
    ...(parsed.data.scheduledFor !== undefined ? { scheduledFor: parsed.data.scheduledFor } : {}),
  }

  const updated = await prisma.order.update({ where: { id: orderId }, data })
  return NextResponse.json(updated)
}
