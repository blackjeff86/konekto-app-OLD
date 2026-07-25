import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    guest: { findUnique: vi.fn() },
    order: { count: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signGuestToken } from '@/lib/guest-auth'
import { GET } from './route'

function getRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/guest/orders/unseen-count', {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

const guestPayload = { sub: 'guest_1', hotelId: 'hotel_1', firstName: 'Jefferson', lastName: 'Brito', roomNumber: '701' }

describe('GET /api/guest/orders/unseen-count', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({
      id: 'guest_1',
      stayId: 'stay_1',
      status: 'active',
      stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000) },
    } as never)
  })

  it('returns 401 without a valid guest token', async () => {
    const response = await GET(getRequest(null))
    expect(response.status).toBe(401)
  })

  it('returns the count of orders not yet seen by the guest', async () => {
    const token = await signGuestToken(guestPayload)
    vi.mocked(prisma.order.count).mockResolvedValue(3)

    const response = await GET(getRequest(token))

    expect(response.status).toBe(200)
    expect(await response.json()).toEqual({ count: 3 })
    expect(prisma.order.count).toHaveBeenCalledWith({ where: { guestId: 'guest_1', statusSeenByGuest: false } })
  })
})
