import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformSupportMessage: { findMany: vi.fn(), create: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { GET, POST } from './route'

function makeRequest(method: string, hotelId: string, token: string | null, body?: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/support-messages`, {
    method,
    headers: {
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  })
}

async function staffToken(role: 'gerente' | 'recepcao' = 'gerente', hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role, email: 'a@b.com', name: 'A' })
}

describe('/api/hotels/[hotelId]/support-messages', () => {
  beforeEach(() => vi.clearAllMocks())

  it('GET rejects staff from a different hotel', async () => {
    const token = await staffToken('gerente', 'hotel_2')

    const response = await GET(makeRequest('GET', 'hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(403)
  })

  it('GET returns the thread for the hotel', async () => {
    const token = await staffToken()
    vi.mocked(prisma.platformSupportMessage.findMany).mockResolvedValue([{ id: 'm1', body: 'oi' }] as never)

    const response = await GET(makeRequest('GET', 'hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body).toHaveLength(1)
  })

  it('POST allows recepcao (not just gerente) to send a message', async () => {
    const token = await staffToken('recepcao')
    vi.mocked(prisma.platformSupportMessage.create).mockResolvedValue({ id: 'm1', body: 'preciso de ajuda' } as never)

    const response = await POST(makeRequest('POST', 'hotel_1', token, { message: 'preciso de ajuda' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(201)
    expect(prisma.platformSupportMessage.create).toHaveBeenCalledWith({
      data: {
        hotelId: 'hotel_1',
        senderType: 'hotel',
        staffId: 's1',
        body: 'preciso de ajuda',
        readByHotel: true,
        readByPlatform: false,
      },
    })
  })

  it('POST rejects an empty message', async () => {
    const token = await staffToken()

    const response = await POST(makeRequest('POST', 'hotel_1', token, { message: '' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })
})
