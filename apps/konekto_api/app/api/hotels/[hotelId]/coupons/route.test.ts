import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    coupon: {
      findMany: vi.fn(),
      create: vi.fn(),
    },
  },
}))

import { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { POST } from './route'

function postRequest(hotelId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/coupons`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

const validCoupon = {
  title: '10% de desconto',
  description: 'Desconto de boas-vindas',
  code: 'welcome10',
  discountType: 'percentage',
  discountValue: 10,
};

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('POST /api/hotels/[hotelId]/coupons', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a percentage discount over 100', async () => {
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', token, { ...validCoupon, discountValue: 150 }),
      { params: Promise.resolve({ hotelId: 'hotel_1' }) },
    )

    expect(response.status).toBe(400)
  })

  it('rejects a recepcao token (only gerente can create coupons)', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await POST(postRequest('hotel_1', token, validCoupon), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('uppercases the code and creates the coupon', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.coupon.create).mockImplementation(
      (async (args: { data: Record<string, unknown> }) => ({ id: 'coupon_1', ...args.data })) as never,
    )

    const response = await POST(postRequest('hotel_1', token, validCoupon), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(201)
    const body = await response.json()
    expect(body.code).toBe('WELCOME10')
  })

  it('returns 409 when the coupon code already exists for the hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.coupon.create).mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
        code: 'P2002',
        clientVersion: 'test',
      }),
    )

    const response = await POST(postRequest('hotel_1', token, validCoupon), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(409)
  })
})
