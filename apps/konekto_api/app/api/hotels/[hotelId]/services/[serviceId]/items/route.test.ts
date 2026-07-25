import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn() },
    serviceItem: { aggregate: vi.fn(), create: vi.fn() },
    partner: { findFirst: vi.fn() },
  },
}))
vi.mock('@/lib/translate', () => ({ autoTranslateOrNull: vi.fn().mockResolvedValue(null) }))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { POST } from './route'

function postRequest(hotelId: string, serviceId: string, token: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services/${serviceId}/items`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

const params = Promise.resolve({ hotelId: 'hotel_1', serviceId: 'svc_1' })

describe('POST .../items — validação de agendamento', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.serviceItem.aggregate).mockResolvedValue({ _max: { position: null } } as never)
  })

  it('creates an item without any scheduling fields (legacy behavior)', async () => {
    vi.mocked(prisma.serviceItem.create).mockResolvedValue({ id: 'item_1' } as never)
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, { name: 'Massagem', description: 'desc' }),
      { params },
    )

    expect(response.status).toBe(201)
  })

  it('creates an item with a complete scheduling config', async () => {
    vi.mocked(prisma.serviceItem.create).mockResolvedValue({ id: 'item_1' } as never)
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, {
        name: 'Massagem',
        description: 'desc',
        durationMinutes: 60,
        capacityPerSlot: 1,
        availableDaysOfWeek: [2, 3, 4, 5, 6, 7],
        availabilityStartMinute: 840,
        availabilityEndMinute: 1380,
      }),
      { params },
    )

    expect(response.status).toBe(201)
  })

  it('rejects durationMinutes set without the other required scheduling fields', async () => {
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, { name: 'Massagem', description: 'desc', durationMinutes: 60 }),
      { params },
    )

    expect(response.status).toBe(400)
    expect(prisma.serviceItem.create).not.toHaveBeenCalled()
  })

  it('rejects a duration that does not fit the availability window', async () => {
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, {
        name: 'Massagem',
        description: 'desc',
        durationMinutes: 120,
        capacityPerSlot: 1,
        availableDaysOfWeek: [2],
        availabilityStartMinute: 840,
        availabilityEndMinute: 900,
      }),
      { params },
    )

    expect(response.status).toBe(400)
    expect(prisma.serviceItem.create).not.toHaveBeenCalled()
  })

  it('creates an item flagged as minibar', async () => {
    vi.mocked(prisma.serviceItem.create).mockResolvedValue({ id: 'item_1', isMinibarItem: true } as never)
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, { name: 'Água Mineral', description: 'desc', price: 5, isMinibarItem: true }),
      { params },
    )

    expect(response.status).toBe(201)
    expect(prisma.serviceItem.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ isMinibarItem: true }) }),
    )
  })

  it('rejects paymentMode: partner without a partnerId', async () => {
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, { name: 'Massagem', description: 'desc', paymentMode: 'partner' }),
      { params },
    )

    expect(response.status).toBe(400)
    expect(prisma.serviceItem.create).not.toHaveBeenCalled()
  })

  it('rejects a partnerId that does not belong to this hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.findFirst).mockResolvedValue(null)

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, {
        name: 'Massagem',
        description: 'desc',
        partnerId: 'p1',
        paymentMode: 'partner',
      }),
      { params },
    )

    expect(response.status).toBe(400)
    expect(prisma.serviceItem.create).not.toHaveBeenCalled()
  })

  it('creates an item linked to a partner with direct payment', async () => {
    vi.mocked(prisma.partner.findFirst).mockResolvedValue({ id: 'p1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.serviceItem.create).mockResolvedValue({ id: 'item_1', partnerId: 'p1', paymentMode: 'partner' } as never)
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', 'svc_1', token, {
        name: 'Massagem',
        description: 'desc',
        partnerId: 'p1',
        paymentMode: 'partner',
      }),
      { params },
    )

    expect(response.status).toBe(201)
    expect(prisma.serviceItem.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ partnerId: 'p1', paymentMode: 'partner' }) }),
    )
  })
})
