import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    order: { findUnique: vi.fn(), update: vi.fn(), count: vi.fn() },
    serviceItem: { findUnique: vi.fn() },
    restaurantTableType: { findUnique: vi.fn() },
    service: { findUnique: vi.fn() },
    guest: { findUnique: vi.fn() },
    $transaction: vi.fn(),
  },
}))

import { prisma } from '@/lib/prisma'
import { signGuestToken } from '@/lib/guest-auth'
import { PATCH } from './route'

const activeGuest = {
  id: 'guest_1',
  stayId: 'stay_1',
  status: 'active',
  stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000) },
}

function patchRequest(orderId: string, token: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/orders/${orderId}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

async function guestToken() {
  return signGuestToken({ sub: 'guest_1', hotelId: 'hotel_1', firstName: 'A', lastName: 'B', roomNumber: '101' })
}

const params = Promise.resolve({ orderId: 'order_1' })

// Próxima terça-feira às 14:00 UTC — sempre no futuro, independente de
// quando os testes rodam de verdade (`isValidScheduledSlot` rejeita
// qualquer horário que não esteja estritamente no futuro).
function nextOccurrenceOfWeekday(isoWeekday: number, hour: number, minute: number, from: Date = new Date()): Date {
  const candidate = new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate(), hour, minute, 0, 0))
  const currentIsoWeekday = candidate.getUTCDay() === 0 ? 7 : candidate.getUTCDay()
  let daysToAdd = (isoWeekday - currentIsoWeekday + 7) % 7
  if (daysToAdd === 0 && candidate.getTime() <= from.getTime()) daysToAdd = 7
  candidate.setUTCDate(candidate.getUTCDate() + daysToAdd)
  return candidate
}

describe('PATCH /api/orders/[orderId]', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(activeGuest as never)
  })

  it('cancels a pending order without touching scheduling', async () => {
    vi.mocked(prisma.order.findUnique).mockResolvedValue({
      id: 'order_1',
      guestId: 'guest_1',
      status: 'pending',
      couponId: null,
      serviceItemId: 'item_1',
    } as never)
    vi.mocked(prisma.order.update).mockResolvedValue({ id: 'order_1', status: 'cancelled' } as never)
    const token = await guestToken()

    const response = await PATCH(patchRequest('order_1', token, { cancel: true }), { params })

    expect(response.status).toBe(200)
    expect(prisma.order.update).toHaveBeenCalledWith({ where: { id: 'order_1' }, data: { status: 'cancelled' } })
  })

  it('updates note/quantity directly for an item without scheduling configured', async () => {
    vi.mocked(prisma.order.findUnique).mockResolvedValue({
      id: 'order_1',
      guestId: 'guest_1',
      status: 'pending',
      couponId: null,
      serviceItemId: 'item_1',
    } as never)
    vi.mocked(prisma.serviceItem.findUnique).mockResolvedValue({ id: 'item_1', durationMinutes: null } as never)
    vi.mocked(prisma.order.update).mockResolvedValue({ id: 'order_1', quantity: 2 } as never)
    const token = await guestToken()

    const response = await PATCH(patchRequest('order_1', token, { quantity: 2 }), { params })

    expect(response.status).toBe(200)
    expect(prisma.$transaction).not.toHaveBeenCalled()
  })

  describe('reagendando um item com agendamento configurado', () => {
    const scheduledItem = {
      id: 'item_spa',
      durationMinutes: 60,
      capacityPerSlot: 1,
      availableDaysOfWeek: [2, 3, 4, 5, 6, 7],
      availabilityStartMinute: 840,
      availabilityEndMinute: 1380,
    }
    const validSlot = nextOccurrenceOfWeekday(2, 14, 0)

    beforeEach(() => {
      vi.mocked(prisma.order.findUnique).mockResolvedValue({
        id: 'order_1',
        guestId: 'guest_1',
        status: 'pending',
        couponId: null,
        serviceItemId: 'item_spa',
      } as never)
      vi.mocked(prisma.serviceItem.findUnique).mockResolvedValue(scheduledItem as never)
    })

    it('rejects an invalid time (not on a slot boundary) without touching the order', async () => {
      const token = await guestToken()
      const offBoundary = new Date(validSlot.getTime() + 15 * 60 * 1000)

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: offBoundary.toISOString() }),
        { params },
      )

      expect(response.status).toBe(400)
      expect(await response.json()).toEqual({ error: 'invalid_schedule' })
      expect(prisma.$transaction).not.toHaveBeenCalled()
    })

    it('reschedules inside a locked transaction, excluding the order itself from the capacity count', async () => {
      const token = await guestToken()
      const tx = {
        $executeRaw: vi.fn(),
        order: {
          count: vi.fn().mockResolvedValue(0),
          update: vi.fn().mockResolvedValue({ id: 'order_1', scheduledFor: validSlot }),
        },
      }
      vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(200)
      expect(tx.$executeRaw).toHaveBeenCalled()
      expect(tx.order.count).toHaveBeenCalledWith({
        where: { serviceItemId: 'item_spa', scheduledFor: validSlot, status: { not: 'cancelled' }, id: { not: 'order_1' } },
      })
      expect(tx.order.update).toHaveBeenCalled()
    })

    it('rejects with 409 slot_full when the destination slot is already at capacity', async () => {
      const token = await guestToken()
      const tx = {
        $executeRaw: vi.fn(),
        order: { count: vi.fn().mockResolvedValue(1), update: vi.fn() },
      }
      vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(409)
      expect(await response.json()).toEqual({ error: 'slot_full' })
      expect(tx.order.update).not.toHaveBeenCalled()
    })
  })

  describe('reagendando uma reserva de mesa com tipo de mesa configurado', () => {
    const validSlot = nextOccurrenceOfWeekday(2, 19, 0)

    beforeEach(() => {
      vi.mocked(prisma.order.findUnique).mockResolvedValue({
        id: 'order_1',
        guestId: 'guest_1',
        status: 'pending',
        couponId: null,
        serviceItemId: 'table_item',
        tableTypeId: 'table_4',
      } as never)
      // O item "Reserva de mesa" (oculto) nunca tem `durationMinutes` — sem
      // isso explícito aqui, o mock herdaria o valor configurado pelo
      // describe anterior (`scheduledItem`, com agendamento), fazendo a
      // rota tomar o branch errado (item de atividade em vez de mesa).
      vi.mocked(prisma.serviceItem.findUnique).mockResolvedValue({ id: 'table_item', durationMinutes: null } as never)
      vi.mocked(prisma.restaurantTableType.findUnique).mockResolvedValue({
        id: 'table_4',
        seats: 4,
        quantity: 2,
        service: { type: 'restaurant', operatingDaysOfWeek: [], operatingStartMinute: null, operatingEndMinute: null },
      } as never)
    })

    it('rejects a reschedule that lands outside operating hours', async () => {
      vi.mocked(prisma.restaurantTableType.findUnique).mockResolvedValue({
        id: 'table_4',
        seats: 4,
        quantity: 2,
        service: { type: 'restaurant', operatingDaysOfWeek: [1, 2, 3, 4, 5, 6, 7], operatingStartMinute: 0, operatingEndMinute: 1 },
      } as never)
      const token = await guestToken()

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(400)
      expect(await response.json()).toEqual({ error: 'service_closed' })
      expect(prisma.$transaction).not.toHaveBeenCalled()
    })

    it('reschedules inside a locked transaction, excluding the order itself from the capacity count', async () => {
      const token = await guestToken()
      const tx = {
        $executeRaw: vi.fn(),
        order: {
          count: vi.fn().mockResolvedValue(0),
          update: vi.fn().mockResolvedValue({ id: 'order_1', scheduledFor: validSlot }),
        },
      }
      vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(200)
      expect(tx.$executeRaw).toHaveBeenCalled()
      expect(tx.order.count).toHaveBeenCalledWith({
        where: { tableTypeId: 'table_4', scheduledFor: validSlot, status: { not: 'cancelled' }, id: { not: 'order_1' } },
      })
      expect(tx.order.update).toHaveBeenCalled()
    })

    it('rejects with 409 table_full when the destination slot is already at capacity', async () => {
      const token = await guestToken()
      const tx = {
        $executeRaw: vi.fn(),
        order: { count: vi.fn().mockResolvedValue(2), update: vi.fn() },
      }
      vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(409)
      expect(await response.json()).toEqual({ error: 'table_full' })
      expect(tx.order.update).not.toHaveBeenCalled()
    })
  })

  describe('reagendando uma reserva de mesa SEM tipo de mesa configurado (legado)', () => {
    const validSlot = nextOccurrenceOfWeekday(2, 19, 0)

    beforeEach(() => {
      vi.mocked(prisma.order.findUnique).mockResolvedValue({
        id: 'order_1',
        guestId: 'guest_1',
        status: 'pending',
        couponId: null,
        serviceItemId: 'table_item',
        tableTypeId: null,
        serviceId: 'svc_restaurant',
      } as never)
      // Item "Reserva de mesa" (oculto) nunca tem `durationMinutes`.
      vi.mocked(prisma.serviceItem.findUnique).mockResolvedValue({ id: 'table_item', durationMinutes: null } as never)
    })

    it('rejects a reschedule outside operating hours even with no table type to check capacity against', async () => {
      vi.mocked(prisma.service.findUnique).mockResolvedValue({
        id: 'svc_restaurant',
        type: 'restaurant',
        operatingDaysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        operatingStartMinute: 0,
        operatingEndMinute: 1,
      } as never)
      const token = await guestToken()

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(400)
      expect(await response.json()).toEqual({ error: 'service_closed' })
      expect(prisma.order.update).not.toHaveBeenCalled()
    })

    it('rejects a reschedule to a past instant', async () => {
      vi.mocked(prisma.service.findUnique).mockResolvedValue({
        id: 'svc_restaurant',
        type: 'restaurant',
        operatingDaysOfWeek: [],
        operatingStartMinute: null,
        operatingEndMinute: null,
      } as never)
      const token = await guestToken()
      const pastInstant = new Date(Date.now() - 60 * 60 * 1000)

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: pastInstant.toISOString() }),
        { params },
      )

      expect(response.status).toBe(400)
      expect(await response.json()).toEqual({ error: 'invalid_request' })
      expect(prisma.order.update).not.toHaveBeenCalled()
    })

    it('accepts a valid reschedule (no capacity check possible without a table type)', async () => {
      vi.mocked(prisma.service.findUnique).mockResolvedValue({
        id: 'svc_restaurant',
        type: 'restaurant',
        operatingDaysOfWeek: [],
        operatingStartMinute: null,
        operatingEndMinute: null,
      } as never)
      vi.mocked(prisma.order.update).mockResolvedValue({ id: 'order_1', scheduledFor: validSlot } as never)
      const token = await guestToken()

      const response = await PATCH(
        patchRequest('order_1', token, { scheduledFor: validSlot.toISOString() }),
        { params },
      )

      expect(response.status).toBe(200)
      expect(prisma.order.update).toHaveBeenCalledWith({
        where: { id: 'order_1' },
        data: { scheduledFor: validSlot },
      })
      expect(prisma.$transaction).not.toHaveBeenCalled()
    })
  })
})
