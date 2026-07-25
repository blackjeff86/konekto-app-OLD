import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    staff: { findMany: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { GET } from './route'

function getRequest(hotelId: string, token: string | null): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/staff`, {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('GET /api/hotels/[hotelId]/staff', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a recepcao token (only gerente can list the team)', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await GET(getRequest('hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(403)
  })

  it('rejects a gerente token from a different hotel', async () => {
    const token = await gerenteToken('hotel_2')

    const response = await GET(getRequest('hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(403)
  })

  it('returns the hotel staff without passwordHash', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.staff.findMany).mockResolvedValue([
      { id: 's1', name: 'A', email: 'a@b.com', role: 'gerente', createdAt: new Date() },
    ] as never)

    const response = await GET(getRequest('hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body).toHaveLength(1)
    expect(body[0].passwordHash).toBeUndefined()
    expect(prisma.staff.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { hotelId: 'hotel_1' } }),
    )
  })
})
