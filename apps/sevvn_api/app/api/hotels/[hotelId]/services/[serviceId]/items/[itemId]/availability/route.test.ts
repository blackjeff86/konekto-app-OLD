import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    serviceItem: { findFirst: vi.fn() },
    order: { groupBy: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { GET } from './route'

function getRequest(hotelId: string, serviceId: string, itemId: string, date: string): NextRequest {
  return new NextRequest(
    `http://localhost/api/hotels/${hotelId}/services/${serviceId}/items/${itemId}/availability?date=${date}`,
  )
}

const params = Promise.resolve({ hotelId: 'hotel_1', serviceId: 'svc_1', itemId: 'item_spa' })

const scheduledItem = {
  id: 'item_spa',
  durationMinutes: 60,
  capacityPerSlot: 2,
  availableDaysOfWeek: [2, 3, 4, 5, 6, 7],
  availabilityStartMinute: 840, // 14:00
  availabilityEndMinute: 960, // 16:00 — só 2 slots pra manter o teste simples
}

describe('GET .../items/[itemId]/availability', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns invalid_request for a malformed date', async () => {
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue(scheduledItem as never)
    const response = await GET(getRequest('hotel_1', 'svc_1', 'item_spa', 'not-a-date'), { params })
    expect(response.status).toBe(400)
  })

  it('returns item_not_found for an unknown item', async () => {
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue(null)
    const response = await GET(getRequest('hotel_1', 'svc_1', 'item_spa', '2026-07-21'), { params })
    expect(response.status).toBe(404)
  })

  it('returns schedulingEnabled: false when the item has no scheduling configured', async () => {
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({ id: 'item_spa', durationMinutes: null } as never)
    const response = await GET(getRequest('hotel_1', 'svc_1', 'item_spa', '2026-07-21'), { params })
    expect(await response.json()).toEqual({ schedulingEnabled: false })
  })

  it('returns an empty slot list for a day of the week outside availableDaysOfWeek', async () => {
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue(scheduledItem as never)
    // 2026-07-20 é segunda-feira, fora de [2..7]
    const response = await GET(getRequest('hotel_1', 'svc_1', 'item_spa', '2026-07-20'), { params })
    expect(await response.json()).toEqual({ schedulingEnabled: true, durationMinutes: 60, slots: [] })
  })

  it('marks a slot as unavailable once it reaches capacity', async () => {
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue(scheduledItem as never)
    vi.mocked(prisma.order.groupBy).mockResolvedValue([
      { scheduledFor: new Date('2026-07-21T14:00:00.000Z'), _count: { _all: 2 } },
    ] as never)

    const response = await GET(getRequest('hotel_1', 'svc_1', 'item_spa', '2026-07-21'), { params })

    expect(await response.json()).toEqual({
      schedulingEnabled: true,
      durationMinutes: 60,
      slots: [
        { time: '14:00', available: false },
        { time: '15:00', available: true },
      ],
    })
  })
})
