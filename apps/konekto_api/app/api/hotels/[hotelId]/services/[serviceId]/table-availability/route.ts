import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { canonicalizeSlotStart, isBookableInstant, isWithinOperatingHours } from '@/lib/scheduling'

export const runtime = 'nodejs'

const querySchema = z.object({
  scheduledFor: z.coerce.date(),
})

// Disponibilidade de mesas de um restaurante num instante escolhido pelo
// hóspede — sem auth (mesmo nível de acesso do endpoint de disponibilidade
// por item: informação pública, necessária pra montar a tela de reserva
// antes do claim de estadia). Reserva de mesa não tem grade de horários com
// duração fixa (diferente de atividade) — o hóspede escolhe livremente
// dentro do horário de funcionamento, e aqui devolvemos a disponibilidade
// EXATA daquele instante.
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params

  const parsedQuery = querySchema.safeParse({ scheduledFor: request.nextUrl.searchParams.get('scheduledFor') })
  if (!parsedQuery.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const service = await prisma.service.findUnique({
    where: { id: serviceId, hotelId },
    include: { tableTypes: true },
  })
  if (!service || service.type !== 'restaurant') {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  if (!isBookableInstant(parsedQuery.data.scheduledFor)) {
    return NextResponse.json({ ok: false, error: 'invalid_request' }, { status: 400 })
  }
  if (!isWithinOperatingHours(service, parsedQuery.data.scheduledFor)) {
    return NextResponse.json({ ok: false, error: 'service_closed' })
  }

  const canonicalScheduledFor = canonicalizeSlotStart(parsedQuery.data.scheduledFor)

  const reservationsAtInstant = await prisma.order.groupBy({
    by: ['tableTypeId'],
    where: {
      serviceId,
      scheduledFor: canonicalScheduledFor,
      status: { not: 'cancelled' },
      tableTypeId: { not: null },
    },
    _count: { _all: true },
  })
  const countByTableType = new Map<string, number>()
  for (const group of reservationsAtInstant) {
    if (!group.tableTypeId) continue
    countByTableType.set(group.tableTypeId, group._count._all)
  }

  const tableTypes = service.tableTypes.map((tableType) => ({
    id: tableType.id,
    label: tableType.label,
    seats: tableType.seats,
    totalQuantity: tableType.quantity,
    availableQuantity: Math.max(0, tableType.quantity - (countByTableType.get(tableType.id) ?? 0)),
  }))

  return NextResponse.json({ ok: true, tableTypes })
}
