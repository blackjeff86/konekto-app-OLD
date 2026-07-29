import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { notifyStaffRecordedMinibarConsumption } from '@/lib/basic-notifications'
import { readHotelModuleConfiguration } from '@/lib/hotel-modules'

export const runtime = 'nodejs'

function readRoomServiceConfig(hotelConfig: unknown) {
  const configuration = readHotelModuleConfiguration(hotelConfig, 'room_service')
  return {
    allowStaffConsumptionLaunch:
      typeof configuration.allowStaffConsumptionLaunch === 'boolean'
        ? configuration.allowStaffConsumptionLaunch
        : true,
  }
}

const recordConsumptionSchema = z.object({
  guestId: z.string().min(1),
  serviceItemId: z.string().min(1),
  quantity: z.number().int().positive().default(1),
})

// A recepção lança um consumo de frigobar em nome de um hóspede da estadia
// (ex: notou um item faltando na conferência do quarto) — mesmo `Order` que
// o próprio hóspede usaria pra se autoinformar (`POST /api/orders`), só que
// criado pelo staff. Só serve pra itens marcados `isMinibarItem`: essa rota
// não é uma porta de trás pra lançar QUALQUER pedido em nome de um hóspede.
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; stayId: string }> },
) {
  const { hotelId, stayId } = await params

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

  const parsed = recordConsumptionSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const stay = await prisma.stay.findFirst({ where: { id: stayId, hotelId } })
  if (!stay) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }

  const hotel = await prisma.hotel.findUnique({
    where: { id: hotelId },
    select: { config: true },
  })
  const roomServiceConfig = readRoomServiceConfig(hotel?.config)
  if (!roomServiceConfig.allowStaffConsumptionLaunch) {
    return NextResponse.json({ error: 'staff_consumption_launch_disabled' }, { status: 403 })
  }

  const guest = await prisma.guest.findFirst({ where: { id: parsed.data.guestId, stayId } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const item = await prisma.serviceItem.findFirst({
    where: { id: parsed.data.serviceItemId, service: { hotelId } },
    include: { service: true },
  })
  if (!item || !item.isMinibarItem) {
    return NextResponse.json({ error: 'item_not_found' }, { status: 400 })
  }

  const order = await prisma.order.create({
    data: {
      hotelId,
      guestId: guest.id,
      serviceId: item.serviceId,
      serviceItemId: item.id,
      itemName: item.name,
      price: item.price,
      quantity: parsed.data.quantity,
      status: 'completed',
      recordedByStaffId: staff.sub,
      // Cobrança nova que o hóspede não iniciou — ainda não viu, então conta
      // no sino de notificações até ele abrir "Meus Pedidos".
      statusSeenByGuest: false,
    },
  })
  await notifyStaffRecordedMinibarConsumption({
    hotelId,
    guestId: guest.id,
    orderId: order.id,
    itemName: item.name,
    quantity: parsed.data.quantity,
  })
  return NextResponse.json(order, { status: 201 })
}
