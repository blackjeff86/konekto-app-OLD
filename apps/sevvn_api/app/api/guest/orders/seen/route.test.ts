import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    guest: { findUnique: vi.fn() },
    order: { updateMany: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signGuestToken } from '@/lib/guest-auth'
import { POST } from './route'

function postRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/guest/orders/seen', {
    method: 'POST',
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

const guestPayload = { sub: 'guest_1', hotelId: 'hotel_1', firstName: 'Jefferson', lastName: 'Brito', roomNumber: '701' }

describe('POST /api/guest/orders/seen', () => {
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
    const response = await POST(postRequest(null))
    expect(response.status).toBe(401)
  })

  it('marks all of the guest\'s unseen orders as seen', async () => {
    const token = await signGuestToken(guestPayload)
    vi.mocked(prisma.order.updateMany).mockResolvedValue({ count: 2 } as never)

    const response = await POST(postRequest(token))

    expect(response.status).toBe(200)
    expect(prisma.order.updateMany).toHaveBeenCalledWith({
      where: { guestId: 'guest_1', statusSeenByGuest: false },
      data: { statusSeenByGuest: true },
    })
  })
})
