import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformSupportMessage: { updateMany: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { POST } from './route'

function postRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/hotels/hotel_1/support-messages/read', {
    method: 'POST',
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

describe('POST /api/platform-admin/hotels/[hotelId]/support-messages/read', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid platform-admin token', async () => {
    const response = await POST(postRequest(null), { params: Promise.resolve({ hotelId: 'hotel_1' }) })
    expect(response.status).toBe(401)
  })

  it('marks hotel messages as read by the platform', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.platformSupportMessage.updateMany).mockResolvedValue({ count: 3 } as never)

    const response = await POST(postRequest(token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    expect(prisma.platformSupportMessage.updateMany).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1', senderType: 'hotel', readByPlatform: false },
      data: { readByPlatform: true },
    })
  })
})
