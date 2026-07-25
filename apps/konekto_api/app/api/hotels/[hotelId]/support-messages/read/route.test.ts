import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformSupportMessage: { updateMany: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { POST } from './route'

function postRequest(hotelId: string, token: string): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/support-messages/read`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}` },
  })
}

describe('POST /api/hotels/[hotelId]/support-messages/read', () => {
  beforeEach(() => vi.clearAllMocks())

  it('marks platform messages as read by the hotel', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.platformSupportMessage.updateMany).mockResolvedValue({ count: 2 } as never)

    const response = await POST(postRequest('hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    expect(prisma.platformSupportMessage.updateMany).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1', senderType: 'platform', readByHotel: false },
      data: { readByHotel: true },
    })
  })
})
