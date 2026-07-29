import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    order: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { PATCH } from './route'

function patchRequest(hotelId: string, orderId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/orders/${orderId}`, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

describe('PATCH /api/hotels/[hotelId]/orders/[orderId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid staff token', async () => {
    const response = await PATCH(patchRequest('hotel_1', 'order_1', null, { status: 'in_progress' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', orderId: 'order_1' }),
    })
    expect(response.status).toBe(401)
  })

  it('returns 403 when the staff token belongs to a different hotel', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_2', role: 'gerente', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', 'order_1', token, { status: 'in_progress' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', orderId: 'order_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('rejects an invalid status value', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', 'order_1', token, { status: 'not_a_status' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', orderId: 'order_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('returns 404 when the order does not belong to this hotel', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.order.findUnique).mockResolvedValue(null)

    const response = await PATCH(patchRequest('hotel_1', 'order_1', token, { status: 'in_progress' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', orderId: 'order_1' }),
    })

    expect(response.status).toBe(404)
  })

  it('updates the status and marks it unseen by the guest', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.order.findUnique).mockResolvedValue({ id: 'order_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.order.update).mockResolvedValue({ id: 'order_1', status: 'in_progress' } as never)

    const response = await PATCH(patchRequest('hotel_1', 'order_1', token, { status: 'in_progress' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', orderId: 'order_1' }),
    })

    expect(response.status).toBe(200)
    expect(prisma.order.update).toHaveBeenCalledWith({
      where: { id: 'order_1' },
      data: { status: 'in_progress', statusSeenByGuest: false },
    })
  })
})
