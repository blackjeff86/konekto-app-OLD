import { NextRequest } from 'next/server'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    serviceItem: { findFirst: vi.fn(), create: vi.fn() },
    service: { findFirst: vi.fn() },
    order: { create: vi.fn(), count: vi.fn(), findMany: vi.fn() },
    guest: { findUnique: vi.fn() },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/integration-webhook', () => ({ dispatchOrderWebhook: vi.fn() }))
vi.mock('@/lib/stay-expiration', () => ({ expireStay: vi.fn() }))

import { prisma } from '@/lib/prisma'
import { dispatchOrderWebhook } from '@/lib/integration-webhook'
import { signGuestToken } from '@/lib/guest-auth'
import { POST } from './route'

function postRequest(token: string, body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/orders', {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

async function guestToken() {
  return signGuestToken({ sub: 'guest_1', hotelId: 'hotel_1', firstName: 'A', lastName: 'B', roomNumber: '101' })
}

const activeGuest = {
  id: 'guest_1',
  stayId: 'stay_1',
  status: 'active',
  stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000) },
}

// Encontra a próxima ocorrência futura (estritamente depois de `from`) de
// um weekday ISO num horário fixo — usado pra gerar datas de fixture que
// nunca ficam "no passado" conforme o tempo real avança (`isBookableInstant`
// rejeita qualquer `scheduledFor` que não esteja estritamente no futuro).
function nextOccurrenceOfWeekday(isoWeekday: number, hour: number, minute: number, from: Date = new Date()): Date {
  const candidate = new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate(), hour, minute, 0, 0))
  const currentIsoWeekday = candidate.getUTCDay() === 0 ? 7 : candidate.getUTCDay()
  let daysToAdd = (isoWeekday - currentIsoWeekday + 7) % 7
  if (daysToAdd === 0 && candidate.getTime() <= from.getTime()) daysToAdd = 7
  candidate.setUTCDate(candidate.getUTCDate() + daysToAdd)
  return candidate
}

describe('POST /api/orders — integration webhook dispatch', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
  })

  it('dispatches the order webhook after creating a regular item order', async () => {
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      name: 'Club Sandwich',
      price: 39.9,
      service: { type: 'activity' },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1' } as never)

    const response = await POST(postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_1', quantity: 1 }))

    expect(response.status).toBe(201)
    expect(dispatchOrderWebhook).toHaveBeenCalledWith({ id: 'order_1', hotelId: 'hotel_1' }, 'hotel_1')
  })

  it('dispatches the order webhook after creating a table reservation order', async () => {
    const token = await guestToken()
    vi.mocked(prisma.service.findFirst).mockResolvedValue({ id: 'svc_1', type: 'restaurant', tableTypes: [] } as never)
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({ id: 'table_item', name: 'Reserva de mesa', hidden: true } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_2', hotelId: 'hotel_1' } as never)

    const futureDate = nextOccurrenceOfWeekday(2, 19, 0)
    const response = await POST(postRequest(token, { serviceId: 'svc_1', scheduledFor: futureDate.toISOString() }))

    expect(response.status).toBe(201)
    expect(dispatchOrderWebhook).toHaveBeenCalledWith({ id: 'order_2', hotelId: 'hotel_1' }, 'hotel_1')
  })
})

describe('POST /api/orders — item de frigobar (isMinibarItem)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
  })

  it('creates the order already completed when the guest reports consumption (consumptionReport: true)', async () => {
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      name: 'Água Mineral',
      price: 5,
      isMinibarItem: true,
      durationMinutes: null,
      service: { type: 'room_service' },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1', status: 'completed' } as never)

    const response = await POST(
      postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_1', quantity: 1, consumptionReport: true }),
    )

    expect(response.status).toBe(201)
    expect(prisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: 'completed' }) }),
    )
  })

  it('does NOT force completed when the same minibar item is ordered normally through Room Service (no consumptionReport)', async () => {
    // Ex: "Água Mineral" existe tanto no cardápio de Serviço de Quarto
    // quanto no Frigobar — pedir pra ser entregue segue o preparo normal;
    // só informar consumo (flag explícita) pula direto pra completed.
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      name: 'Água Mineral',
      price: 5,
      isMinibarItem: true,
      durationMinutes: null,
      service: { type: 'room_service' },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1' } as never)

    await POST(postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_1', quantity: 1 }))

    expect(prisma.order.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.not.objectContaining({ status: expect.anything() }) }))
  })

  it('does not force a status for a regular (non-minibar) item even with consumptionReport: true', async () => {
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      name: 'Club Sandwich',
      price: 39.9,
      isMinibarItem: false,
      durationMinutes: null,
      service: { type: 'room_service' },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1' } as never)

    await POST(postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_1', quantity: 1, consumptionReport: true }))

    expect(prisma.order.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.not.objectContaining({ status: expect.anything() }) }))
  })
})

describe('POST /api/orders — item vinculado a um parceiro', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
  })

  it('snapshots paymentMode and the partner name onto the order', async () => {
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      name: 'Massagem relaxante',
      price: 150,
      isMinibarItem: false,
      durationMinutes: null,
      paymentMode: 'partner',
      partner: { id: 'p1', name: 'Studio Bem-Estar' },
      service: { type: 'activity' },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1' } as never)

    await POST(postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_1', quantity: 1 }))

    expect(prisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ paymentMode: 'partner', partnerName: 'Studio Bem-Estar' }),
      }),
    )
  })

  it('snapshots paymentMode: hotel and no partner name for a regular item', async () => {
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      name: 'Club Sandwich',
      price: 39.9,
      isMinibarItem: false,
      durationMinutes: null,
      paymentMode: 'hotel',
      partner: null,
      service: { type: 'room_service' },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1' } as never)

    await POST(postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_1', quantity: 1 }))

    expect(prisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ paymentMode: 'hotel', partnerName: null }) }),
    )
  })
})

describe('POST /api/orders — item com agendamento configurado', () => {
  const scheduledItem = {
    id: 'item_spa',
    name: 'Massagem relaxante',
    price: 150,
    durationMinutes: 60,
    capacityPerSlot: 1,
    availableDaysOfWeek: [2, 3, 4, 5, 6, 7], // terça a domingo
    availabilityStartMinute: 840, // 14:00
    availabilityEndMinute: 1380, // 23:00
    service: { type: 'activity' },
  }
  const validSlot = nextOccurrenceOfWeekday(2, 14, 0) // próxima terça-feira às 14:00
  const invalidWeekday = nextOccurrenceOfWeekday(1, 14, 0) // próxima segunda-feira às 14:00

  function fakeTx(activeCount: number) {
    return {
      $executeRaw: vi.fn(),
      order: {
        count: vi.fn().mockResolvedValue(activeCount),
        create: vi.fn().mockResolvedValue({ id: 'order_scheduled', hotelId: 'hotel_1' }),
      },
    }
  }

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue(scheduledItem as never)
  })

  it('rejects when scheduledFor is missing', async () => {
    const token = await guestToken()
    const response = await POST(postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_spa', quantity: 1 }))

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'invalid_request' })
  })

  it('rejects a time that is not a valid slot boundary', async () => {
    const token = await guestToken()
    const offBoundary = new Date(validSlot.getTime() + 30 * 60 * 1000)
    const response = await POST(
      postRequest(token, {
        serviceId: 'svc_1',
        serviceItemId: 'item_spa',
        quantity: 1,
        scheduledFor: offBoundary.toISOString(),
      }),
    )

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'invalid_schedule' })
  })

  it('rejects a day of the week outside availableDaysOfWeek', async () => {
    const token = await guestToken()
    const response = await POST(
      postRequest(token, {
        serviceId: 'svc_1',
        serviceItemId: 'item_spa',
        quantity: 1,
        scheduledFor: invalidWeekday.toISOString(), // segunda-feira, fora da lista
      }),
    )

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'invalid_schedule' })
  })

  it('rejects an instant that is not strictly in the future', async () => {
    const token = await guestToken()
    const response = await POST(
      postRequest(token, {
        serviceId: 'svc_1',
        serviceItemId: 'item_spa',
        quantity: 1,
        scheduledFor: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
      }),
    )

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'invalid_schedule' })
  })

  it('creates the order inside a locked transaction when the slot has capacity', async () => {
    const token = await guestToken()
    const tx = fakeTx(0)
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    const response = await POST(
      postRequest(token, {
        serviceId: 'svc_1',
        serviceItemId: 'item_spa',
        quantity: 1,
        scheduledFor: validSlot.toISOString(),
      }),
    )

    expect(response.status).toBe(201)
    expect(tx.$executeRaw).toHaveBeenCalled()
    expect(tx.order.count).toHaveBeenCalledWith({
      where: { serviceItemId: 'item_spa', scheduledFor: validSlot, status: { not: 'cancelled' } },
    })
    expect(tx.order.create).toHaveBeenCalled()
    expect(dispatchOrderWebhook).toHaveBeenCalledWith({ id: 'order_scheduled', hotelId: 'hotel_1' }, 'hotel_1')
  })

  it('rejects with 409 slot_full when the slot is already at capacity, without creating an order', async () => {
    const token = await guestToken()
    const tx = fakeTx(1) // capacityPerSlot é 1, já tem 1 ativo
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    const response = await POST(
      postRequest(token, {
        serviceId: 'svc_1',
        serviceItemId: 'item_spa',
        quantity: 1,
        scheduledFor: validSlot.toISOString(),
      }),
    )

    expect(response.status).toBe(409)
    expect(await response.json()).toEqual({ error: 'slot_full' })
    expect(tx.order.create).not.toHaveBeenCalled()
    expect(dispatchOrderWebhook).not.toHaveBeenCalled()
  })
})

describe('POST /api/orders — Serviço de Quarto com horário de funcionamento', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('rejects an order placed outside the configured operating hours', async () => {
    // "Agora" fixado às 03:00 de uma quarta-feira (weekday 3) — fora da
    // janela 07:00-23:00 configurada abaixo. A rota usa `new Date()` real
    // (sem seam de teste, de propósito — não é código de produção que
    // deveria aceitar um "now" injetado), então fixamos o relógio do
    // processo pra tornar o teste determinístico.
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-07-22T03:00:00Z'))

    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_room_service',
      name: 'Club Sandwich',
      price: 39.9,
      durationMinutes: null,
      service: {
        type: 'room_service',
        operatingDaysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        operatingStartMinute: 420,
        operatingEndMinute: 1380,
      },
    } as never)

    const response = await POST(
      postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_room_service', quantity: 1 }),
    )

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'service_closed' })
    expect(prisma.order.create).not.toHaveBeenCalled()
  })

  it('accepts an order when no operating hours are configured', async () => {
    const token = await guestToken()
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_room_service',
      name: 'Club Sandwich',
      price: 39.9,
      durationMinutes: null,
      service: { type: 'room_service', operatingDaysOfWeek: [], operatingStartMinute: null, operatingEndMinute: null },
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_room_service', hotelId: 'hotel_1' } as never)

    const response = await POST(
      postRequest(token, { serviceId: 'svc_1', serviceItemId: 'item_room_service', quantity: 1 }),
    )

    expect(response.status).toBe(201)
  })
})

describe('POST /api/orders — reserva de mesa com tipo de mesa configurado', () => {
  const validSlot = nextOccurrenceOfWeekday(2, 19, 0)

  function fakeTx(activeCount: number) {
    return {
      $executeRaw: vi.fn(),
      order: {
        count: vi.fn().mockResolvedValue(activeCount),
        create: vi.fn().mockResolvedValue({ id: 'order_table', hotelId: 'hotel_1' }),
      },
    }
  }

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
    vi.mocked(prisma.service.findFirst).mockResolvedValue({
      id: 'svc_restaurant',
      type: 'restaurant',
      operatingDaysOfWeek: [],
      operatingStartMinute: null,
      operatingEndMinute: null,
      tableTypes: [{ id: 'table_4', seats: 4, quantity: 2, label: null }],
    } as never)
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({ id: 'table_item', name: 'Reserva de mesa', hidden: true } as never)
  })

  it('rejects an unknown tableTypeId', async () => {
    const token = await guestToken()
    const response = await POST(
      postRequest(token, { serviceId: 'svc_restaurant', scheduledFor: validSlot.toISOString(), tableTypeId: 'does_not_exist' }),
    )

    expect(response.status).toBe(404)
    expect(await response.json()).toEqual({ error: 'table_type_not_found' })
  })

  it('reserves a table inside a locked transaction when the table type has capacity', async () => {
    const token = await guestToken()
    const tx = fakeTx(1) // quantity é 2, já tem 1 ativa
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    const response = await POST(
      postRequest(token, { serviceId: 'svc_restaurant', scheduledFor: validSlot.toISOString(), tableTypeId: 'table_4' }),
    )

    expect(response.status).toBe(201)
    expect(tx.$executeRaw).toHaveBeenCalled()
    expect(tx.order.count).toHaveBeenCalledWith({
      where: { tableTypeId: 'table_4', scheduledFor: validSlot, status: { not: 'cancelled' } },
    })
  })

  it('rejects with 409 table_full when the table type is already at capacity', async () => {
    const token = await guestToken()
    const tx = fakeTx(2) // quantity é 2, já tem 2 ativas
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    const response = await POST(
      postRequest(token, { serviceId: 'svc_restaurant', scheduledFor: validSlot.toISOString(), tableTypeId: 'table_4' }),
    )

    expect(response.status).toBe(409)
    expect(await response.json()).toEqual({ error: 'table_full' })
    expect(tx.order.create).not.toHaveBeenCalled()
  })

  it('rejects a reservation outside the restaurant operating hours', async () => {
    vi.mocked(prisma.service.findFirst).mockResolvedValue({
      id: 'svc_restaurant',
      type: 'restaurant',
      operatingDaysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      operatingStartMinute: 0,
      operatingEndMinute: 1,
      tableTypes: [{ id: 'table_4', seats: 4, quantity: 2, label: null }],
    } as never)
    const token = await guestToken()

    const response = await POST(
      postRequest(token, { serviceId: 'svc_restaurant', scheduledFor: validSlot.toISOString(), tableTypeId: 'table_4' }),
    )

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'service_closed' })
  })
})
