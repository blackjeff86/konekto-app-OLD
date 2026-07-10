import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const createOrderSchema = z.object({
  serviceId: z.string().min(1),
  serviceItemId: z.string().min(1),
  quantity: z.number().int().min(1).default(1),
  note: z.string().trim().max(500).optional(),
  scheduledFor: z.coerce.date().optional(),
})

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
