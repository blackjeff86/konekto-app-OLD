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
  // Cupom escolhido da lista de elegíveis (`GET /api/coupons`) — o hóspede
  // nunca digita um código, só o id do cupom já validado como elegível.
  // Só vale pra itens com preço (branch `serviceItemId`); reserva de mesa
  // não tem preço nenhum, então nem faz sentido aplicar desconto.
  couponId: z.string().min(1).optional(),
})

const TABLE_RESERVATION_ITEM_NAME = 'Reserva de mesa'

interface CouponApplication {
  finalPrice: number | null
  discountAmount: number | null
  couponId: string | null
}

type CouponApplicationResult =
  | { ok: true; application: CouponApplication }
  | { ok: false; response: NextResponse }

// Revalida o cupom inteiro no servidor (nunca confia que o app já filtrou
// certo) — elegibilidade pode ter mudado entre o hóspede abrir a lista e
// confirmar o pedido (outro pedido no meio, cupom expirou, etc.
async function applyCoupon(options: {
  couponId: string
  hotelId: string
  guestId: string
  itemPrice: number | null
  quantity: number
}): Promise<CouponApplicationResult> {
  const coupon = await prisma.coupon.findFirst({
    where: { id: options.couponId, hotelId: options.hotelId, enabled: true },
  })
  if (!coupon) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_not_found' }, { status: 404 }) }
  }

  const now = new Date()
  if (coupon.validFrom && now < coupon.validFrom) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_not_yet_valid' }, { status: 400 }) }
  }
  if (coupon.validUntil && now > coupon.validUntil) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_expired' }, { status: 400 }) }
  }
  if (options.itemPrice == null) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_not_applicable' }, { status: 400 }) }
  }

  const subtotal = options.itemPrice * options.quantity
  if (coupon.minOrderValue != null && subtotal < coupon.minOrderValue) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_min_order_not_met' }, { status: 400 }) }
  }

  const [totalUses, guestUses] = await Promise.all([
    coupon.usageLimit != null
      ? prisma.order.count({ where: { couponId: coupon.id } })
      : Promise.resolve(0),
    prisma.order.count({ where: { couponId: coupon.id, guestId: options.guestId } }),
  ])
  if (coupon.usageLimit != null && totalUses >= coupon.usageLimit) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_usage_limit_reached' }, { status: 409 }) }
  }
  if (guestUses >= coupon.perGuestLimit) {
    return { ok: false, response: NextResponse.json({ error: 'coupon_already_used' }, { status: 409 }) }
  }

  const rawDiscount = coupon.discountType === 'percentage' ? subtotal * (coupon.discountValue / 100) : coupon.discountValue
  const discountAmount = Math.min(rawDiscount, subtotal)
  const finalPrice = (subtotal - discountAmount) / options.quantity

  return { ok: true, application: { finalPrice, discountAmount, couponId: coupon.id } }
}

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

    let finalPrice = item.price
    let discountAmount: number | null = null
    let appliedCouponId: string | null = null

    if (parsed.data.couponId) {
      const result = await applyCoupon({
        couponId: parsed.data.couponId,
        hotelId: guest.hotelId,
        guestId: guest.sub,
        itemPrice: item.price,
        quantity: parsed.data.quantity,
      })
      if (!result.ok) return result.response
      finalPrice = result.application.finalPrice
      discountAmount = result.application.discountAmount
      appliedCouponId = result.application.couponId
    }

    const order = await prisma.order.create({
      data: {
        hotelId: guest.hotelId,
        guestId: guest.sub,
        serviceId: parsed.data.serviceId,
        serviceItemId: parsed.data.serviceItemId,
        itemName: item.name,
        price: finalPrice,
        quantity: parsed.data.quantity,
        note: parsed.data.note || null,
        scheduledFor: parsed.data.scheduledFor,
        couponId: appliedCouponId,
        discountAmount,
      },
      include: { coupon: { select: { title: true } } },
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
    include: { coupon: { select: { title: true } } },
  })
  return NextResponse.json(orders)
}
