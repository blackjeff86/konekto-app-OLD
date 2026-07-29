import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { generateSlotStartMinutes, isoWeekdayUtc, minuteOfDayToTimeString, minuteOfDayUtc } from '@/lib/scheduling'

export const runtime = 'nodejs'

const querySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
})

// Grade de horários disponíveis pro hóspede reservar um item — sem auth
// (mesmo nível de acesso de `GET .../services/[serviceId]`, que também é
// público: o app do hóspede precisa montar a tela de reserva antes do
// claim de estadia). Não expõe nada sensível, só contagem de ocupação por
// horário, que é exatamente o que o hóspede precisa ver pra escolher.
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string; itemId: string }> },
) {
  const { hotelId, serviceId, itemId } = await params

  const parsedQuery = querySchema.safeParse({ date: request.nextUrl.searchParams.get('date') })
  if (!parsedQuery.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const item = await prisma.serviceItem.findFirst({
    where: { id: itemId, serviceId, service: { hotelId } },
  })
  if (!item) {
    return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
  }

  if (item.durationMinutes == null) {
    return NextResponse.json({ schedulingEnabled: false })
  }

  const requestedDate = new Date(`${parsedQuery.data.date}T00:00:00Z`)
  if (Number.isNaN(requestedDate.getTime())) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const {
    durationMinutes,
    capacityPerSlot,
    availableDaysOfWeek,
    availabilityStartMinute,
    availabilityEndMinute,
  } = item as {
    durationMinutes: number
    capacityPerSlot: number
    availableDaysOfWeek: number[]
    availabilityStartMinute: number
    availabilityEndMinute: number
  }

  if (!availableDaysOfWeek.includes(isoWeekdayUtc(requestedDate))) {
    return NextResponse.json({ schedulingEnabled: true, durationMinutes, slots: [] })
  }

  const slotStartMinutes = generateSlotStartMinutes({ durationMinutes, availabilityStartMinute, availabilityEndMinute })

  const dayStart = requestedDate
  const dayEnd = new Date(requestedDate.getTime() + 24 * 60 * 60 * 1000)
  const ordersThatDay = await prisma.order.groupBy({
    by: ['scheduledFor'],
    where: {
      serviceItemId: itemId,
      status: { not: 'cancelled' },
      scheduledFor: { gte: dayStart, lt: dayEnd },
    },
    _count: { _all: true },
  })
  const countByMinute = new Map<number, number>()
  for (const group of ordersThatDay) {
    if (!group.scheduledFor) continue
    countByMinute.set(minuteOfDayUtc(group.scheduledFor), group._count._all)
  }

  const slots = slotStartMinutes.map((minute) => ({
    time: minuteOfDayToTimeString(minute),
    available: (countByMinute.get(minute) ?? 0) < capacityPerSlot,
  }))

  return NextResponse.json({ schedulingEnabled: true, durationMinutes, slots })
}
