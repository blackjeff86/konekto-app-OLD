import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    restaurantTableType: { findFirst: vi.fn(), update: vi.fn(), delete: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { PATCH, DELETE } from './route'

function patchRequest(hotelId: string, serviceId: string, tableTypeId: string, token: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services/${serviceId}/table-types/${tableTypeId}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  })
}

function deleteRequest(hotelId: string, serviceId: string, tableTypeId: string, token: string): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/services/${serviceId}/table-types/${tableTypeId}`, {
    method: 'DELETE',
    headers: { authorization: `Bearer ${token}` },
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

const params = Promise.resolve({ hotelId: 'hotel_1', serviceId: 'svc_1', tableTypeId: 'table_4' })

describe('PATCH .../table-types/[tableTypeId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('updates the quantity of an existing table type', async () => {
    vi.mocked(prisma.restaurantTableType.findFirst).mockResolvedValue({ id: 'table_4', seats: 4, quantity: 10 } as never)
    vi.mocked(prisma.restaurantTableType.update).mockResolvedValue({ id: 'table_4', seats: 4, quantity: 0 } as never)
    const token = await gerenteToken()

    const response = await PATCH(patchRequest('hotel_1', 'svc_1', 'table_4', token, { quantity: 0 }), { params })

    expect(response.status).toBe(200)
    expect(prisma.restaurantTableType.update).toHaveBeenCalledWith({ where: { id: 'table_4' }, data: { quantity: 0 } })
  })

  it('returns table_type_not_found for an unknown or cross-hotel table type', async () => {
    vi.mocked(prisma.restaurantTableType.findFirst).mockResolvedValue(null)
    const token = await gerenteToken()

    const response = await PATCH(patchRequest('hotel_1', 'svc_1', 'table_4', token, { quantity: 0 }), { params })

    expect(response.status).toBe(404)
    expect(prisma.restaurantTableType.update).not.toHaveBeenCalled()
  })
})

describe('DELETE .../table-types/[tableTypeId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('deletes an existing table type', async () => {
    vi.mocked(prisma.restaurantTableType.findFirst).mockResolvedValue({ id: 'table_4', seats: 4, quantity: 10 } as never)
    const token = await gerenteToken()

    const response = await DELETE(deleteRequest('hotel_1', 'svc_1', 'table_4', token), { params })

    expect(response.status).toBe(200)
    expect(prisma.restaurantTableType.delete).toHaveBeenCalledWith({ where: { id: 'table_4' } })
  })

  it('rejects a request from staff of a different hotel', async () => {
    const token = await gerenteToken('hotel_2')

    const response = await DELETE(deleteRequest('hotel_1', 'svc_1', 'table_4', token), { params })

    expect(response.status).toBe(403)
    expect(prisma.restaurantTableType.delete).not.toHaveBeenCalled()
  })
})
