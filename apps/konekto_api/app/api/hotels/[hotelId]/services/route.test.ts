import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn(), findMany: vi.fn(), aggregate: vi.fn(), create: vi.fn() },
  },
}))
vi.mock('@/lib/translate', () => ({ autoTranslateOrNull: vi.fn().mockResolvedValue(null) }))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { POST } from './route'

function postRequest(hotelId: string, token: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

const params = Promise.resolve({ hotelId: 'hotel_1' })

const baseBody = {
  name: 'Room Service',
  slug: 'room-service',
  icon: 'room_service',
  description: 'desc',
  type: 'room_service',
  category: 'Quarto',
}

describe('POST .../services — validação de horário de funcionamento', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(prisma.service.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.service.aggregate).mockResolvedValue({ _max: { position: null } } as never)
  })

  it('creates a service without any operating-hours fields (legacy behavior)', async () => {
    vi.mocked(prisma.service.create).mockResolvedValue({ id: 'svc_1' } as never)
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', token, baseBody), { params })

    expect(response.status).toBe(201)
  })

  it('creates a service with a complete operating-hours config, including an overnight window', async () => {
    vi.mocked(prisma.service.create).mockResolvedValue({ id: 'svc_1' } as never)
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', token, {
        ...baseBody,
        operatingDaysOfWeek: [5, 6],
        operatingStartMinute: 1140,
        operatingEndMinute: 60,
      }),
      { params },
    )

    expect(response.status).toBe(201)
  })

  it('rejects operatingStartMinute set without the other required fields', async () => {
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', token, { ...baseBody, operatingStartMinute: 420 }), { params })

    expect(response.status).toBe(400)
    expect(prisma.service.create).not.toHaveBeenCalled()
  })

  it('rejects start === end (zero-width window)', async () => {
    const token = await gerenteToken()

    const response = await POST(
      postRequest('hotel_1', token, {
        ...baseBody,
        operatingDaysOfWeek: [1],
        operatingStartMinute: 600,
        operatingEndMinute: 600,
      }),
      { params },
    )

    expect(response.status).toBe(400)
    expect(prisma.service.create).not.toHaveBeenCalled()
  })
})
