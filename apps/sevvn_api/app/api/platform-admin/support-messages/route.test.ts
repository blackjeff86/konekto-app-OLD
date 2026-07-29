import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformSupportMessage: { findMany: vi.fn(), count: vi.fn() },
    hotel: { findMany: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { GET } from './route'

function getRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/support-messages', {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

describe('GET /api/platform-admin/support-messages', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid platform-admin token', async () => {
    const response = await GET(getRequest(null))
    expect(response.status).toBe(401)
  })

  it('returns one thread summary per hotel with a message, with hotel name and unread count', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.platformSupportMessage.findMany).mockResolvedValue([
      { hotelId: 'hotel_1', body: 'preciso de ajuda', senderType: 'hotel', createdAt: new Date('2026-07-20T10:00:00Z') },
    ] as never)
    vi.mocked(prisma.hotel.findMany).mockResolvedValue([
      { id: 'hotel_1', config: { hotelInfo: { name: 'Amara Bay' } } },
    ] as never)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(1)

    const response = await GET(getRequest(token))

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body).toHaveLength(1)
    expect(body[0]).toMatchObject({ hotelId: 'hotel_1', hotelName: 'Amara Bay', unreadByPlatform: 1 })
  })

  it('queries with distinct hotelId ordered by most recent, the Prisma "latest per group" pattern', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.platformSupportMessage.findMany).mockResolvedValue([])
    vi.mocked(prisma.hotel.findMany).mockResolvedValue([])

    await GET(getRequest(token))

    expect(prisma.platformSupportMessage.findMany).toHaveBeenCalledWith({
      distinct: ['hotelId'],
      orderBy: { createdAt: 'desc' },
    })
  })
})
