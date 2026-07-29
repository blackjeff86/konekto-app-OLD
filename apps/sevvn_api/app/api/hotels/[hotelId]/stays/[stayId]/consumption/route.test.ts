import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    stay: { findFirst: vi.fn() },
    guest: { findFirst: vi.fn() },
    serviceItem: { findFirst: vi.fn() },
    order: { create: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { POST } from './route'

function postRequest(hotelId: string, stayId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/stays/${stayId}/consumption`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

async function staffToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'recepcao', email: 'a@b.com', name: 'Recepcionista' })
}

const validBody = { guestId: 'guest_1', serviceItemId: 'item_1', quantity: 2 }

describe('POST /api/hotels/[hotelId]/stays/[stayId]/consumption', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid staff token', async () => {
    const response = await POST(postRequest('hotel_1', 'stay_1', null, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })
    expect(response.status).toBe(401)
  })

  it('returns 403 when the staff token belongs to a different hotel', async () => {
    const token = await staffToken('hotel_2')
    const response = await POST(postRequest('hotel_1', 'stay_1', token, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })
    expect(response.status).toBe(403)
  })

  it('rejects an invalid body', async () => {
    const token = await staffToken()
    const response = await POST(postRequest('hotel_1', 'stay_1', token, { guestId: 'guest_1' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })
    expect(response.status).toBe(400)
  })

  it('returns 404 when the stay does not belong to this hotel', async () => {
    const token = await staffToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue(null)

    const response = await POST(postRequest('hotel_1', 'stay_1', token, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(404)
  })

  it('returns 404 when the guest does not belong to this stay', async () => {
    const token = await staffToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue({ id: 'stay_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.guest.findFirst).mockResolvedValue(null)

    const response = await POST(postRequest('hotel_1', 'stay_1', token, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(404)
    expect(prisma.guest.findFirst).toHaveBeenCalledWith({ where: { id: 'guest_1', stayId: 'stay_1' } })
  })

  it('rejects an item that is not flagged isMinibarItem', async () => {
    const token = await staffToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue({ id: 'stay_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.guest.findFirst).mockResolvedValue({ id: 'guest_1', stayId: 'stay_1' } as never)
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      serviceId: 'service_1',
      name: 'Prato qualquer',
      price: 10,
      isMinibarItem: false,
    } as never)

    const response = await POST(postRequest('hotel_1', 'stay_1', token, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(400)
    expect(prisma.order.create).not.toHaveBeenCalled()
  })

  it('returns 400 when the item does not exist for this hotel', async () => {
    const token = await staffToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue({ id: 'stay_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.guest.findFirst).mockResolvedValue({ id: 'guest_1', stayId: 'stay_1' } as never)
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue(null)

    const response = await POST(postRequest('hotel_1', 'stay_1', token, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('creates a completed order recorded by the staff member, unseen by the guest', async () => {
    const token = await staffToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue({ id: 'stay_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.guest.findFirst).mockResolvedValue({ id: 'guest_1', stayId: 'stay_1' } as never)
    vi.mocked(prisma.serviceItem.findFirst).mockResolvedValue({
      id: 'item_1',
      serviceId: 'service_1',
      name: 'Água Mineral',
      price: 5,
      isMinibarItem: true,
    } as never)
    vi.mocked(prisma.order.create).mockResolvedValue({ id: 'order_1' } as never)

    const response = await POST(postRequest('hotel_1', 'stay_1', token, validBody), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(201)
    expect(prisma.order.create).toHaveBeenCalledWith({
      data: {
        hotelId: 'hotel_1',
        guestId: 'guest_1',
        serviceId: 'service_1',
        serviceItemId: 'item_1',
        itemName: 'Água Mineral',
        price: 5,
        quantity: 2,
        status: 'completed',
        recordedByStaffId: 'staff_1',
        statusSeenByGuest: false,
      },
    })
  })
})
