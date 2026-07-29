import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    staff: { findUnique: vi.fn(), count: vi.fn(), delete: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { DELETE } from './route'

function deleteRequest(hotelId: string, staffId: string, token: string | null): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/staff/${staffId}`, {
    method: 'DELETE',
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('DELETE /api/hotels/[hotelId]/staff/[staffId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a recepcao token', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await DELETE(deleteRequest('hotel_1', 's2', token), {
      params: Promise.resolve({ hotelId: 'hotel_1', staffId: 's2' }),
    })

    expect(response.status).toBe(403)
  })

  it('returns 404 when the target staff belongs to a different hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.staff.findUnique).mockResolvedValue({ id: 's2', hotelId: 'hotel_2', role: 'recepcao' } as never)

    const response = await DELETE(deleteRequest('hotel_1', 's2', token), {
      params: Promise.resolve({ hotelId: 'hotel_1', staffId: 's2' }),
    })

    expect(response.status).toBe(404)
    expect(prisma.staff.delete).not.toHaveBeenCalled()
  })

  it('removes a recepcao staff member without checking manager count', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.staff.findUnique).mockResolvedValue({ id: 's2', hotelId: 'hotel_1', role: 'recepcao' } as never)

    const response = await DELETE(deleteRequest('hotel_1', 's2', token), {
      params: Promise.resolve({ hotelId: 'hotel_1', staffId: 's2' }),
    })

    expect(response.status).toBe(200)
    expect(prisma.staff.count).not.toHaveBeenCalled()
    expect(prisma.staff.delete).toHaveBeenCalledWith({ where: { id: 's2' } })
  })

  it('blocks removing the last gerente of the hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.staff.findUnique).mockResolvedValue({ id: 's1', hotelId: 'hotel_1', role: 'gerente' } as never)
    vi.mocked(prisma.staff.count).mockResolvedValue(1)

    const response = await DELETE(deleteRequest('hotel_1', 's1', token), {
      params: Promise.resolve({ hotelId: 'hotel_1', staffId: 's1' }),
    })

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBe('cannot_remove_last_manager')
    expect(prisma.staff.delete).not.toHaveBeenCalled()
  })

  it('allows removing a gerente when another gerente still exists', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.staff.findUnique).mockResolvedValue({ id: 's2', hotelId: 'hotel_1', role: 'gerente' } as never)
    vi.mocked(prisma.staff.count).mockResolvedValue(2)

    const response = await DELETE(deleteRequest('hotel_1', 's2', token), {
      params: Promise.resolve({ hotelId: 'hotel_1', staffId: 's2' }),
    })

    expect(response.status).toBe(200)
    expect(prisma.staff.delete).toHaveBeenCalledWith({ where: { id: 's2' } })
  })
})
