import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotel: { findUnique: vi.fn() },
    staff: { findMany: vi.fn() },
  },
}))

vi.mock('@/lib/platform-admin-hotel-shape', () => ({
  buildHotelOverview: vi.fn(async (hotel: { id: string }) => ({ hotelId: hotel.id, name: hotel.id })),
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { GET } from './route'

function getRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/hotels/hotel_1', {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

describe('GET /api/platform-admin/hotels/[hotelId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid platform-admin token', async () => {
    const response = await GET(getRequest(null), { params: Promise.resolve({ hotelId: 'hotel_1' }) })
    expect(response.status).toBe(401)
  })

  it('returns 404 when the hotel does not exist', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue(null)

    const response = await GET(getRequest(token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(404)
  })

  it('returns the hotel overview plus its staff list', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: {}, createdAt: new Date() } as never)
    vi.mocked(prisma.staff.findMany).mockResolvedValue([
      { id: 's1', name: 'Gerente', email: 'g@hotel.com', role: 'gerente', createdAt: new Date() },
    ] as never)

    const response = await GET(getRequest(token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.hotelId).toBe('hotel_1')
    expect(body.staff).toHaveLength(1)
    expect(body.staff[0].email).toBe('g@hotel.com')
  })
})
