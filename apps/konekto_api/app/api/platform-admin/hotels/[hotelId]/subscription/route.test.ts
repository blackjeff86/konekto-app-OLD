import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotel: { findUnique: vi.fn() },
    hotelSubscription: { upsert: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { PATCH } from './route'

function patchRequest(token: string | null, body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/hotels/hotel_1/subscription', {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  })
}

const validBody = { planName: 'Pro', status: 'active', paymentStatus: 'em_dia' }

describe('PATCH /api/platform-admin/hotels/[hotelId]/subscription', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid platform-admin token', async () => {
    const response = await PATCH(patchRequest(null, validBody), { params: Promise.resolve({ hotelId: 'hotel_1' }) })
    expect(response.status).toBe(401)
  })

  it('rejects an invalid body', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })

    const response = await PATCH(patchRequest(token, { planName: '', status: 'active', paymentStatus: 'em_dia' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('returns 404 when the hotel does not exist', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue(null)

    const response = await PATCH(patchRequest(token, validBody), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(404)
  })

  it('upserts the subscription on success', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1' } as never)
    vi.mocked(prisma.hotelSubscription.upsert).mockResolvedValue({
      hotelId: 'hotel_1',
      planName: 'Pro',
      monthlyAmount: null,
      status: 'active',
      paymentStatus: 'em_dia',
      notes: null,
    } as never)

    const response = await PATCH(patchRequest(token, validBody), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    expect(prisma.hotelSubscription.upsert).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      create: { hotelId: 'hotel_1', planName: 'Pro', monthlyAmount: undefined, status: 'active', paymentStatus: 'em_dia', notes: undefined },
      update: { planName: 'Pro', monthlyAmount: undefined, status: 'active', paymentStatus: 'em_dia', notes: undefined },
    })
  })

  it('accepts and forwards a monthlyAmount', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1' } as never)
    vi.mocked(prisma.hotelSubscription.upsert).mockResolvedValue({ hotelId: 'hotel_1' } as never)

    await PATCH(patchRequest(token, { ...validBody, monthlyAmount: 499.9 }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(prisma.hotelSubscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({ monthlyAmount: 499.9 }),
        update: expect.objectContaining({ monthlyAmount: 499.9 }),
      }),
    )
  })

  it('rejects a negative monthlyAmount', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })

    const response = await PATCH(patchRequest(token, { ...validBody, monthlyAmount: -1 }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('accepts and forwards the White Label plan', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1' } as never)
    vi.mocked(prisma.hotelSubscription.upsert).mockResolvedValue({ hotelId: 'hotel_1' } as never)

    await PATCH(patchRequest(token, { ...validBody, plan: 'premium' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(prisma.hotelSubscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({ plan: 'premium' }),
        update: expect.objectContaining({ plan: 'premium' }),
      }),
    )
  })

  it('rejects an invalid plan value', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })

    const response = await PATCH(patchRequest(token, { ...validBody, plan: 'gold' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })
})
