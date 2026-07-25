import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    stay: { findMany: vi.fn() },
    room: { findFirst: vi.fn() },
  },
}))

vi.mock('@/lib/stay-expiration', () => ({
  sweepExpiredStays: vi.fn(),
}))

import { prisma } from '@/lib/prisma'
import { sweepExpiredStays } from '@/lib/stay-expiration'
import { signStaffToken } from '@/lib/jwt'
import { GET } from './route'

function getRequest(hotelId: string, token: string): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/stays`, {
    headers: { authorization: `Bearer ${token}` },
  })
}

describe('GET /api/hotels/[hotelId]/stays', () => {
  beforeEach(() => vi.clearAllMocks())

  it('sweeps overdue stays for the hotel before listing them', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.stay.findMany).mockResolvedValue([])

    const response = await GET(getRequest('hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    expect(sweepExpiredStays).toHaveBeenCalledWith('hotel_1')
  })
})
