import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    stay: { findFirst: vi.fn(), update: vi.fn(), $transaction: vi.fn() },
    room: { findFirst: vi.fn() },
    guest: { updateMany: vi.fn() },
    $transaction: vi.fn(),
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { PATCH } from './route'

function patchRequest(hotelId: string, stayId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/stays/${stayId}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

const activeStay = { id: 'stay_1', hotelId: 'hotel_1', roomId: 'room_1', status: 'active' }

describe('PATCH /api/hotels/[hotelId]/stays/[stayId] — room reassignment', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects moving a closed stay to a different room', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue({ ...activeStay, status: 'closed' } as never)

    const response = await PATCH(patchRequest('hotel_1', 'stay_1', token, { roomId: 'room_2' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBe('stay_not_active')
  })

  it('returns 404 when the target room does not belong to the hotel', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue(activeStay as never)
    vi.mocked(prisma.room.findFirst).mockResolvedValue(null)

    const response = await PATCH(patchRequest('hotel_1', 'stay_1', token, { roomId: 'room_2' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(404)
  })

  it('rejects moving into a room that already has an active stay', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.stay.findFirst)
      .mockResolvedValueOnce(activeStay as never) // existing stay lookup
      .mockResolvedValueOnce({ id: 'stay_2', roomId: 'room_2', status: 'active' } as never) // conflicting stay lookup
    vi.mocked(prisma.room.findFirst).mockResolvedValue({ id: 'room_2', hotelId: 'hotel_1' } as never)

    const response = await PATCH(patchRequest('hotel_1', 'stay_1', token, { roomId: 'room_2' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(409)
    const body = await response.json()
    expect(body.error).toBe('room_already_occupied')
    expect(prisma.stay.update).not.toHaveBeenCalled()
  })

  it('allows moving into a free room', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.stay.findFirst)
      .mockResolvedValueOnce(activeStay as never)
      .mockResolvedValueOnce(null)
    vi.mocked(prisma.room.findFirst).mockResolvedValue({ id: 'room_2', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.stay.update).mockResolvedValue({
      id: 'stay_1',
      room: { number: '202' },
    } as never)

    const response = await PATCH(patchRequest('hotel_1', 'stay_1', token, { roomId: 'room_2' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(200)
    expect(prisma.stay.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ roomId: 'room_2' }) }),
    )
  })

  it('is a no-op guard when roomId is unchanged (skips the conflict check)', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.stay.findFirst).mockResolvedValue(activeStay as never)
    vi.mocked(prisma.stay.update).mockResolvedValue({ id: 'stay_1', room: { number: '101' } } as never)

    const response = await PATCH(patchRequest('hotel_1', 'stay_1', token, { roomId: 'room_1' }), {
      params: Promise.resolve({ hotelId: 'hotel_1', stayId: 'stay_1' }),
    })

    expect(response.status).toBe(200)
    expect(prisma.room.findFirst).not.toHaveBeenCalled()
  })
})
