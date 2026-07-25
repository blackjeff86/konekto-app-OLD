import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformSupportMessage: { findMany: vi.fn(), create: vi.fn() },
    hotel: { findUnique: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { GET, POST } from './route'

function makeRequest(method: string, token: string | null, body?: unknown): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/hotels/hotel_1/support-messages', {
    method,
    headers: {
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  })
}

describe('/api/platform-admin/hotels/[hotelId]/support-messages', () => {
  beforeEach(() => vi.clearAllMocks())

  it('GET returns 401 without a valid platform-admin token', async () => {
    const response = await GET(makeRequest('GET', null), { params: Promise.resolve({ hotelId: 'hotel_1' }) })
    expect(response.status).toBe(401)
  })

  it('GET returns the thread for that hotel', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.platformSupportMessage.findMany).mockResolvedValue([{ id: 'm1' }] as never)

    const response = await GET(makeRequest('GET', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
  })

  it('POST returns 404 when the hotel does not exist', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue(null)

    const response = await POST(makeRequest('POST', token, { message: 'oi' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(404)
  })

  it('POST creates a reply as senderType: platform', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1' } as never)
    vi.mocked(prisma.platformSupportMessage.create).mockResolvedValue({ id: 'm2', body: 'já vamos verificar' } as never)

    const response = await POST(makeRequest('POST', token, { message: 'já vamos verificar' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(201)
    expect(prisma.platformSupportMessage.create).toHaveBeenCalledWith({
      data: {
        hotelId: 'hotel_1',
        senderType: 'platform',
        body: 'já vamos verificar',
        readByPlatform: true,
        readByHotel: false,
      },
    })
  })
})
