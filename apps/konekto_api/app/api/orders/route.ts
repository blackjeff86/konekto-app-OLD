import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import type { Order, Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'
import { dispatchOrderWebhook } from '@/lib/integration-webhook'
import { canonicalizeSlotStart, isBookableInstant, isValidScheduledSlot, isWithinOperatingHours } from '@/lib/scheduling'

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
  // Só vale na reserva de mesa (`serviceItemId` omitido) — qual tipo de
  // mesa o hóspede escolheu depois de ver a disponibilidade em
  // `GET .../table-availability`. Omitido = restaurante sem tipos de mesa
  // cadastrados, comportamento legado sem checagem de capacidade.
  tableTypeId: z.string().min(1).optional(),
  // Só o app manda `true` quando o hóspede usou o fluxo "Informar consumo"
  // do Frigobar — o MESMO item (`ServiceItem.isMinibarItem`) pode ser
  // pedido normalmente pelo Serviço de Quarto sem essa flag (ex: pedir
  // mais uma água pra ser entregue, em vez de informar que já bebeu uma).
  // Só tem efeito se o item também for `isMinibarItem`; ignorado
  // silenciosamente em qualquer outro item (ver branch abaixo).
  consumptionReport: z.boolean().optional(),
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
      include: { service: true, partner: true },
    })
    if (!item) {
      return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
    }

    // Serviço de Quarto com horário de funcionamento configurado (cozinha
    // que fecha de madrugada, por exemplo) — bloqueia o pedido fora do
    // horário. Não afeta `activity` (que já tem seu próprio controle fino
    // por item) nem `restaurant` (a checagem de horário dele é na branch de
    // reserva de mesa, mais abaixo).
    if (item.service.type === 'room_service' && !isWithinOperatingHours(item.service, new Date())) {
      return NextResponse.json({ error: 'service_closed' }, { status: 400 })
    }

    // Item com agendamento configurado (`durationMinutes` setado — ver
    // `lib/scheduling.ts`): `scheduledFor` é obrigatório e precisa bater
    // exatamente num horário válido, revalidado no servidor (nunca confia
    // que o app só deixou o hóspede escolher um slot da grade certa).
    // Canonizado (segundos/ms zerados) ANTES de virar a chave do lock ou
    // entrar na contagem de capacidade — sem isso, dois pedidos pro "mesmo"
    // horário com segundos diferentes (só possível batendo direto na API)
    // contariam como slots distintos e passariam da capacidade.
    let scheduledFor = parsed.data.scheduledFor
    if (item.durationMinutes != null) {
      if (!scheduledFor) {
        return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
      }
      const validSlot = isValidScheduledSlot(
        {
          durationMinutes: item.durationMinutes,
          availableDaysOfWeek: item.availableDaysOfWeek,
          availabilityStartMinute: item.availabilityStartMinute!,
          availabilityEndMinute: item.availabilityEndMinute!,
        },
        scheduledFor,
      )
      if (!validSlot) {
        return NextResponse.json({ error: 'invalid_schedule' }, { status: 400 })
      }
      scheduledFor = canonicalizeSlotStart(scheduledFor)
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

    const orderData = {
      hotelId: guest.hotelId,
      guestId: guest.sub,
      serviceId: parsed.data.serviceId,
      serviceItemId: parsed.data.serviceItemId,
      itemName: item.name,
      price: finalPrice,
      quantity: parsed.data.quantity,
      note: parsed.data.note || null,
      scheduledFor,
      couponId: appliedCouponId,
      discountAmount,
      // Só nasce direto `completed` (sem passar por `pending`/`in_progress`)
      // quando o hóspede está de fato INFORMANDO um consumo que já
      // aconteceu (`consumptionReport`) — pedir o mesmo item normalmente
      // pelo Serviço de Quarto (sem essa flag) segue o preparo/entrega de
      // sempre, mesmo que o item também seja `isMinibarItem`.
      ...(item.isMinibarItem && parsed.data.consumptionReport ? { status: 'completed' as const } : {}),
      // Snapshot de quem presta o serviço e como é pago — mesmo racional de
      // `itemName`/`price`, sobrevive a uma edição do item/parceiro depois.
      // `paymentMode: 'partner'` exclui esse pedido de `computeStayBill`.
      paymentMode: item.paymentMode,
      partnerName: item.partner?.name ?? null,
    }

    // Sem agendamento configurado nesse item: mesmo caminho de sempre, sem
    // checagem de capacidade (comportamento legado preservado).
    if (item.durationMinutes == null) {
      const order = await prisma.order.create({ data: orderData, include: { coupon: { select: { title: true } } } })
      await dispatchOrderWebhook(order, guest.hotelId)
      return NextResponse.json(order, { status: 201 })
    }

    // Com agendamento: cria dentro de uma transação com advisory lock
    // escopado por item+horário — sem isso, duas reservas concorrentes pro
    // mesmo slot (dois hóspedes, dois cliques) poderiam ambas contar a
    // mesma capacidade livre e passar da vaga. Mesmo padrão já usado em
    // `app/api/guest/stay-bill/pay/route.ts` pra evitar cobrança dupla.
    const lockKey = `${item.id}:${scheduledFor!.toISOString()}`
    type ScheduledCreateResult =
      | { kind: 'full' }
      | { kind: 'ok'; order: Prisma.OrderGetPayload<{ include: { coupon: { select: { title: true } } } }> }

    const result = await prisma.$transaction<ScheduledCreateResult>(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${lockKey}))`

      const activeCount = await tx.order.count({
        where: { serviceItemId: item.id, scheduledFor, status: { not: 'cancelled' } },
      })
      if (activeCount >= item.capacityPerSlot!) {
        return { kind: 'full' }
      }

      const order = await tx.order.create({ data: orderData, include: { coupon: { select: { title: true } } } })
      return { kind: 'ok', order }
    })

    if (result.kind === 'full') {
      return NextResponse.json({ error: 'slot_full' }, { status: 409 })
    }
    await dispatchOrderWebhook(result.order, guest.hotelId)
    return NextResponse.json(result.order, { status: 201 })
  }

  // Reserva de mesa: só vale pra um Service `restaurant`, e sempre precisa
  // de dia/horário. O item "Reserva de mesa" é criado (oculto) na primeira
  // vez que alguém reserva naquele restaurante, e reaproveitado depois —
  // evita uma tabela nova só pra isso, reusa o `Order` existente.
  const service = await prisma.service.findFirst({
    where: { id: parsed.data.serviceId, hotelId: guest.hotelId },
    include: { tableTypes: true },
  })
  if (!service || service.type !== 'restaurant') {
    return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
  }
  if (!parsed.data.scheduledFor) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }
  // Sanidade básica (nunca no passado, não longe demais no futuro) —
  // aplicada sempre, independente de o restaurante ter horário/tipos de
  // mesa configurados, já que reserva de mesa nunca teve NENHUMA validação
  // de data antes disso.
  if (!isBookableInstant(parsed.data.scheduledFor)) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }
  if (!isWithinOperatingHours(service, parsed.data.scheduledFor)) {
    return NextResponse.json({ error: 'service_closed' }, { status: 400 })
  }
  const scheduledFor = canonicalizeSlotStart(parsed.data.scheduledFor)

  // Tipo de mesa é opcional — restaurante sem `RestaurantTableType`
  // cadastrado mantém o comportamento legado (sem checagem de capacidade).
  let tableType: (typeof service.tableTypes)[number] | null = null
  if (parsed.data.tableTypeId) {
    tableType = service.tableTypes.find((candidate) => candidate.id === parsed.data.tableTypeId) ?? null
    if (!tableType) {
      return NextResponse.json({ error: 'table_type_not_found' }, { status: 404 })
    }
  }

  let tableItem = await prisma.serviceItem.findFirst({ where: { serviceId: service.id, hidden: true } })
  if (!tableItem) {
    tableItem = await prisma.serviceItem.create({
      data: { serviceId: service.id, name: TABLE_RESERVATION_ITEM_NAME, description: '', hidden: true },
    })
  }

  const tableOrderData = {
    hotelId: guest.hotelId,
    guestId: guest.sub,
    serviceId: service.id,
    serviceItemId: tableItem.id,
    itemName: tableItem.name,
    price: null,
    quantity: 1,
    note: parsed.data.note || null,
    scheduledFor,
    tableTypeId: tableType?.id ?? null,
  }

  if (!tableType) {
    const order = await prisma.order.create({ data: tableOrderData })
    await dispatchOrderWebhook(order, guest.hotelId)
    return NextResponse.json(order, { status: 201 })
  }

  // Com tipo de mesa: mesmo padrão de transação + advisory lock já usado
  // pra item com agendamento, travando por tipo de mesa + instante exato.
  const lockKey = `table:${tableType.id}:${scheduledFor.toISOString()}`
  type TableReservationResult = { kind: 'full' } | { kind: 'ok'; order: Order }

  const result = await prisma.$transaction<TableReservationResult>(async (tx) => {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${lockKey}))`

    const activeCount = await tx.order.count({
      where: { tableTypeId: tableType.id, scheduledFor, status: { not: 'cancelled' } },
    })
    if (activeCount >= tableType.quantity) {
      return { kind: 'full' }
    }

    const order = await tx.order.create({ data: tableOrderData })
    return { kind: 'ok', order }
  })

  if (result.kind === 'full') {
    return NextResponse.json({ error: 'table_full' }, { status: 409 })
  }
  await dispatchOrderWebhook(result.order, guest.hotelId)
  return NextResponse.json(result.order, { status: 201 })
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
