import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn() },
    order: { groupBy: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { GET } from './route'

function getRequest(hotelId: string, serviceId: string, scheduledFor: string): NextRequest {
  return new NextRequest(
    `http://localhost/api/hotels/${hotelId}/services/${serviceId}/table-availability?scheduledFor=${encodeURIComponent(scheduledFor)}`,
  )
}

const params = Promise.resolve({ hotelId: 'hotel_1', serviceId: 'svc_restaurant' })

function nextOccurrenceOfWeekday(isoWeekday: number, hour: number, minute: number, from: Date = new Date()): Date {
  const candidate = new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth(), from.getUTCDate(), hour, minute, 0, 0))
  const currentIsoWeekday = candidate.getUTCDay() === 0 ? 7 : candidate.getUTCDay()
  let daysToAdd = (isoWeekday - currentIsoWeekday + 7) % 7
  if (daysToAdd === 0 && candidate.getTime() <= from.getTime()) daysToAdd = 7
  candidate.setUTCDate(candidate.getUTCDate() + daysToAdd)
  return candidate
}

const validSlot = nextOccurrenceOfWeekday(2, 19, 0)

const restaurantService = {
  id: 'svc_restaurant',
  type: 'restaurant',
  operatingDaysOfWeek: [],
  operatingStartMinute: null,
  operatingEndMinute: null,
  tableTypes: [
    { id: 'table_4', label: null, seats: 4, quantity: 10 },
    { id: 'table_2', label: null, seats: 2, quantity: 8 },
  ],
}

describe('GET .../table-availability', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns invalid_request for a malformed scheduledFor', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue(restaurantService as never)
    const response = await GET(getRequest('hotel_1', 'svc_restaurant', 'not-a-date'), { params })
    expect(response.status).toBe(400)
  })

  it('returns service_not_found for a non-restaurant service', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ ...restaurantService, type: 'room_service' } as never)
    const response = await GET(getRequest('hotel_1', 'svc_restaurant', validSlot.toISOString()), { params })
    expect(response.status).toBe(404)
  })

  it('returns service_closed when the instant falls outside operating hours', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue({
      ...restaurantService,
      operatingDaysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      operatingStartMinute: 0,
      operatingEndMinute: 1,
    } as never)

    const response = await GET(getRequest('hotel_1', 'svc_restaurant', validSlot.toISOString()), { params })

    expect(await response.json()).toEqual({ ok: false, error: 'service_closed' })
  })

  it('computes availableQuantity per table type from active reservations at that exact instant', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue(restaurantService as never)
    vi.mocked(prisma.order.groupBy).mockResolvedValue([
      { tableTypeId: 'table_4', _count: { _all: 3 } },
    ] as never)

    const response = await GET(getRequest('hotel_1', 'svc_restaurant', validSlot.toISOString()), { params })

    expect(await response.json()).toEqual({
      ok: true,
      tableTypes: [
        { id: 'table_4', label: null, seats: 4, totalQuantity: 10, availableQuantity: 7 },
        { id: 'table_2', label: null, seats: 2, totalQuantity: 8, availableQuantity: 8 },
      ],
    })
  })

  it('never returns a negative availableQuantity even if reservations exceed quantity', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue(restaurantService as never)
    vi.mocked(prisma.order.groupBy).mockResolvedValue([
      { tableTypeId: 'table_4', _count: { _all: 999 } },
    ] as never)

    const response = await GET(getRequest('hotel_1', 'svc_restaurant', validSlot.toISOString()), { params })
    const body = await response.json()

    expect(body.tableTypes.find((t: { id: string }) => t.id === 'table_4').availableQuantity).toBe(0)
  })
})
