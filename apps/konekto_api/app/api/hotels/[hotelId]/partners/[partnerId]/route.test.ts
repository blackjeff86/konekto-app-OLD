import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    partner: { findFirst: vi.fn(), update: vi.fn(), delete: vi.fn() },
    serviceItem: { count: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { PATCH, DELETE } from './route'

function patchRequest(hotelId: string, partnerId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/partners/${partnerId}`, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

function deleteRequest(hotelId: string, partnerId: string, token: string | null): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/partners/${partnerId}`, {
    method: 'DELETE',
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

const params = Promise.resolve({ hotelId: 'hotel_1', partnerId: 'p1' })

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 'staff_1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('PATCH /api/hotels/[hotelId]/partners/[partnerId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid staff token', async () => {
    const response = await PATCH(patchRequest('hotel_1', 'p1', null, { name: 'Novo nome' }), { params })
    expect(response.status).toBe(401)
  })

  it('returns 404 when the partner does not belong to this hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.findFirst).mockResolvedValue(null)

    const response = await PATCH(patchRequest('hotel_1', 'p1', token, { name: 'Novo nome' }), { params })

    expect(response.status).toBe(404)
  })

  it('updates the partner', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.findFirst).mockResolvedValue({ id: 'p1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.partner.update).mockResolvedValue({ id: 'p1', name: 'Novo nome' } as never)

    const response = await PATCH(patchRequest('hotel_1', 'p1', token, { name: 'Novo nome' }), { params })

    expect(response.status).toBe(200)
    expect(prisma.partner.update).toHaveBeenCalledWith({ where: { id: 'p1' }, data: { name: 'Novo nome' } })
  })
})

describe('DELETE /api/hotels/[hotelId]/partners/[partnerId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid staff token', async () => {
    const response = await DELETE(deleteRequest('hotel_1', 'p1', null), { params })
    expect(response.status).toBe(401)
  })

  it('returns 404 when the partner does not belong to this hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.findFirst).mockResolvedValue(null)

    const response = await DELETE(deleteRequest('hotel_1', 'p1', token), { params })

    expect(response.status).toBe(404)
  })

  it('blocks deletion when a service item is still linked (409)', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.findFirst).mockResolvedValue({ id: 'p1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.serviceItem.count).mockResolvedValue(2)

    const response = await DELETE(deleteRequest('hotel_1', 'p1', token), { params })

    expect(response.status).toBe(409)
    expect(await response.json()).toEqual({ error: 'partner_in_use' })
    expect(prisma.partner.delete).not.toHaveBeenCalled()
  })

  it('deletes the partner when no item is linked', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.partner.findFirst).mockResolvedValue({ id: 'p1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.serviceItem.count).mockResolvedValue(0)

    const response = await DELETE(deleteRequest('hotel_1', 'p1', token), { params })

    expect(response.status).toBe(200)
    expect(prisma.partner.delete).toHaveBeenCalledWith({ where: { id: 'p1' } })
  })
})
