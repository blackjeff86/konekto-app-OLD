import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    partner: { findMany: vi.fn(), create: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { GET, POST } from './route'

function getRequest(hotelId: string, token: string | null): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/partners`, {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

function postRequest(hotelId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/partners`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

const params = Promise.resolve({ hotelId: 'hotel_1' })

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

async function recepcaoToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'recepcao', email: 'a@b.com', name: 'A' })
}

describe('GET /api/hotels/[hotelId]/partners', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid staff token', async () => {
    const response = await GET(getRequest('hotel_1', null), { params })
    expect(response.status).toBe(401)
  })

  it('returns 403 when the token belongs to a different hotel', async () => {
    const token = await gerenteToken('hotel_2')
    const response = await GET(getRequest('hotel_1', token), { params })
    expect(response.status).toBe(403)
  })

  it('lists partners for gerente and recepcao alike', async () => {
    const token = await recepcaoToken()
    vi.mocked(prisma.partner.findMany).mockResolvedValue([{ id: 'p1', name: 'Studio Bem-Estar' }] as never)

    const response = await GET(getRequest('hotel_1', token), { params })

    expect(response.status).toBe(200)
    expect(prisma.partner.findMany).toHaveBeenCalledWith({ where: { hotelId: 'hotel_1' }, orderBy: { name: 'asc' } })
  })
})

describe('POST /api/hotels/[hotelId]/partners', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid staff token', async () => {
    const response = await POST(postRequest('hotel_1', null, { name: 'Studio Bem-Estar' }), { params })
    expect(response.status).toBe(401)
  })

  it('rejects a recepcao token (only gerente can create partners)', async () => {
    const token = await recepcaoToken()
    const response = await POST(postRequest('hotel_1', token, { name: 'Studio Bem-Estar' }), { params })
    expect(response.status).toBe(403)
  })

  it('rejects an empty name', async () => {
    const token = await gerenteToken()
    const response = await POST(postRequest('hotel_1', token, { name: '' }), { params })
    expect(response.status).toBe(400)
    expect(prisma.partner.create).not.toHaveBeenCalled()
  })

  it('creates a partner with only the required field', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.create).mockResolvedValue({ id: 'p1', hotelId: 'hotel_1', name: 'Studio Bem-Estar' } as never)

    const response = await POST(postRequest('hotel_1', token, { name: 'Studio Bem-Estar' }), { params })

    expect(response.status).toBe(201)
    expect(prisma.partner.create).toHaveBeenCalledWith({ data: { hotelId: 'hotel_1', name: 'Studio Bem-Estar' } })
  })

  it('creates a partner with all optional contact fields', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.create).mockResolvedValue({ id: 'p1' } as never)
    const body = {
      name: 'Studio Bem-Estar',
      contactName: 'Maria',
      phone: '+5521999999999',
      email: 'maria@studio.com',
      notes: 'Atende só às tardes',
    }

    const response = await POST(postRequest('hotel_1', token, body), { params })

    expect(response.status).toBe(201)
    expect(prisma.partner.create).toHaveBeenCalledWith({ data: { hotelId: 'hotel_1', ...body } })
  })
})
