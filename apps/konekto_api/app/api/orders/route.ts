import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const createOrderSchema = z.object({
  serviceId: z.string().min(1),
  // Omitido = reserva de MESA de um restaurante (não um prato específico)
  // — só válido quando o Service é `type: restaurant`, ver branch abaixo.
  serviceItemId: z.string().min(1).optional(),
  quantity: z.number().int().min(1).default(1),
  note: z.string().trim().max(500).optional(),
  scheduledFor: z.coerce.date().optional(),
})

const TABLE_RESERVATION_ITEM_NAME = 'Reserva de mesa'

// `itemName`/`price` são lidos do ServiceItem no momento da criação (nunca
// do body) — o pedido guarda um snapshot que sobrevive a uma edição ou
// remoção do item depois. `guestId`/`hotelId` sempre do token do hóspede.
export async function POST(request: NextRequest) {
  let guest
  try {
    guest = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = createOrderSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  if (parsed.data.serviceItemId) {
    const item = await prisma.serviceItem.findFirst({
      where: { id: parsed.data.serviceItemId, serviceId: parsed.data.serviceId, service: { hotelId: guest.hotelId } },
    })
    if (!item) {
      return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
    }

    const order = await prisma.order.create({
      data: {
        hotelId: guest.hotelId,
        guestId: guest.sub,
        serviceId: parsed.data.serviceId,
        serviceItemId: parsed.data.serviceItemId,
        itemName: item.name,
        price: item.price,
        quantity: parsed.data.quantity,
        note: parsed.data.note || null,
        scheduledFor: parsed.data.scheduledFor,
      },
    })
    return NextResponse.json(order, { status: 201 })
  }

  // Reserva de mesa: só vale pra um Service `restaurant`, e sempre precisa
  // de dia/horário. O item "Reserva de mesa" é criado (oculto) na primeira
  // vez que alguém reserva naquele restaurante, e reaproveitado depois —
  // evita uma tabela nova só pra isso, reusa o `Order` existente.
  const service = await prisma.service.findFirst({ where: { id: parsed.data.serviceId, hotelId: guest.hotelId } })
  if (!service || service.type !== 'restaurant') {
    return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
  }
  if (!parsed.data.scheduledFor) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  let tableItem = await prisma.serviceItem.findFirst({ where: { serviceId: service.id, hidden: true } })
  if (!tableItem) {
    tableItem = await prisma.serviceItem.create({
      data: { serviceId: service.id, name: TABLE_RESERVATION_ITEM_NAME, description: '', hidden: true },
    })
  }

  const order = await prisma.order.create({
    data: {
      hotelId: guest.hotelId,
      guestId: guest.sub,
      serviceId: service.id,
      serviceItemId: tableItem.id,
      itemName: tableItem.name,
      price: null,
      quantity: 1,
      note: parsed.data.note || null,
      scheduledFor: parsed.data.scheduledFor,
    },
  })
  return NextResponse.json(order, { status: 201 })
}

// Pedidos do PRÓPRIO hóspede autenticado (tela "Meus Pedidos" do app) — não
// confundir com `GET /api/hotels/:hotelId/orders`, que é a visão do staff
// pra todos os hóspedes do hotel.
export async function GET(request: NextRequest) {
  let guest
  try {
    guest = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const orders = await prisma.order.findMany({
    where: { guestId: guest.sub },
    orderBy: { createdAt: 'desc' },
  })
  return NextResponse.json(orders)
}
