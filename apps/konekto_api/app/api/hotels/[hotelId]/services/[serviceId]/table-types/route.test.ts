import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn() },
    restaurantTableType: { findMany: vi.fn(), create: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { GET, POST } from './route'

function getRequest(hotelId: string, serviceId: string): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services/${serviceId}/table-types`)
}

function postRequest(hotelId: string, serviceId: string, token: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services/${serviceId}/table-types`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

const params = Promise.resolve({ hotelId: 'hotel_1', serviceId: 'svc_1' })

describe('GET .../table-types', () => {
  beforeEach(() => vi.clearAllMocks())

  it('lists the table types for the service', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.restaurantTableType.findMany).mockResolvedValue([{ id: 'table_4', seats: 4, quantity: 2 }] as never)

    const response = await GET(getRequest('hotel_1', 'svc_1'), { params })

    expect(response.status).toBe(200)
    expect(await response.json()).toEqual([{ id: 'table_4', seats: 4, quantity: 2 }])
  })

  it('returns service_not_found for an unknown service', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue(null)

    const response = await GET(getRequest('hotel_1', 'svc_1'), { params })

    expect(response.status).toBe(404)
  })
})

describe('POST .../table-types', () => {
  beforeEach(() => vi.clearAllMocks())

  it('creates a table type for a restaurant service', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1', type: 'restaurant' } as never)
    vi.mocked(prisma.restaurantTableType.create).mockResolvedValue({ id: 'table_4', seats: 4, quantity: 10 } as never)
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', 'svc_1', token, { seats: 4, quantity: 10 }), { params })

    expect(response.status).toBe(201)
    expect(prisma.restaurantTableType.create).toHaveBeenCalledWith({
      data: { serviceId: 'svc_1', seats: 4, quantity: 10 },
    })
  })

  it('rejects creating a table type for a non-restaurant service', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1', type: 'room_service' } as never)
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', 'svc_1', token, { seats: 4, quantity: 10 }), { params })

    expect(response.status).toBe(400)
    expect(await response.json()).toEqual({ error: 'not_a_restaurant' })
    expect(prisma.restaurantTableType.create).not.toHaveBeenCalled()
  })

  it('rejects a request from staff of a different hotel', async () => {
    const token = await gerenteToken('hotel_2')

    const response = await POST(postRequest('hotel_1', 'svc_1', token, { seats: 4, quantity: 10 }), { params })

    expect(response.status).toBe(403)
    expect(prisma.restaurantTableType.create).not.toHaveBeenCalled()
  })

  it('rejects invalid seats/quantity', async () => {
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1', type: 'restaurant' } as never)
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', 'svc_1', token, { seats: 0, quantity: -1 }), { params })

    expect(response.status).toBe(400)
    expect(prisma.restaurantTableType.create).not.toHaveBeenCalled()
  })
})
