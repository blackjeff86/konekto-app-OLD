import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    room: { upsert: vi.fn() },
    stay: { findUnique: vi.fn(), findFirst: vi.fn(), upsert: vi.fn() },
    guest: { upsert: vi.fn() },
    hotelIntegration: { update: vi.fn() },
  },
}))

vi.mock('@/lib/auth-guard', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/auth-guard')>()
  return { ...actual, requireIntegrationAuth: vi.fn() }
})

import { prisma } from '@/lib/prisma'
import { requireIntegrationAuth, AuthGuardError } from '@/lib/auth-guard'
import { PUT } from './route'

function putRequest(externalId: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/integrations/v1/reservations/${externalId}`, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', authorization: 'Bearer kk_live_test' },
    body: JSON.stringify(body),
  })
}

const validPayload = {
  roomNumber: '101',
  checkInDate: '2026-07-19T12:00:00.000Z',
  checkOutDate: '2026-07-22T12:00:00.000Z',
  guests: [
    {
      externalId: 'guest-1',
      firstName: 'Maria',
      lastName: 'Silva',
      documentType: 'cpf',
      documentNumber: '12345678900',
      phoneCountryCode: '+55',
      phoneNumber: '11999999999',
      country: 'BR',
    },
  ],
}

describe('PUT /api/integrations/v1/reservations/[externalId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 when the integration key is invalid', async () => {
    vi.mocked(requireIntegrationAuth).mockRejectedValue(
      new AuthGuardError(new Response(null, { status: 401 }) as never),
    )

    const response = await PUT(putRequest('res-1', validPayload), { params: Promise.resolve({ externalId: 'res-1' }) })

    expect(response.status).toBe(401)
  })

  it('rejects an invalid body', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })

    const response = await PUT(putRequest('res-1', { roomNumber: '101' }), {
      params: Promise.resolve({ externalId: 'res-1' }),
    })

    expect(response.status).toBe(400)
  })

  it('creates a Room automatically when the room number is unknown', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.room.upsert).mockResolvedValue({ id: 'room_1', hotelId: 'hotel_1', number: '101' } as never)
    vi.mocked(prisma.stay.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.stay.findFirst).mockResolvedValue(null)
    vi.mocked(prisma.stay.upsert).mockResolvedValue({
      id: 'stay_1',
      hotelId: 'hotel_1',
      externalId: 'res-1',
      roomId: 'room_1',
      status: 'active',
    } as never)
    vi.mocked(prisma.guest.upsert).mockResolvedValue({
      id: 'guest_1',
      externalId: 'guest-1',
      accessCode: 'SV-ABCD12',
    } as never)

    const response = await PUT(putRequest('res-1', validPayload), { params: Promise.resolve({ externalId: 'res-1' }) })

    expect(response.status).toBe(200)
    expect(prisma.room.upsert).toHaveBeenCalledWith({
      where: { hotelId_number: { hotelId: 'hotel_1', number: '101' } },
      create: { hotelId: 'hotel_1', number: '101' },
      update: {},
    })
    const body = await response.json()
    expect(body.guests[0].accessCode).toBe('SV-ABCD12')
  })

  it('returns 409 when the target room already has a different active stay', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.room.upsert).mockResolvedValue({ id: 'room_1', hotelId: 'hotel_1', number: '101' } as never)
    vi.mocked(prisma.stay.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.stay.findFirst).mockResolvedValue({ id: 'stay_other', roomId: 'room_1', status: 'active' } as never)

    const response = await PUT(putRequest('res-1', validPayload), { params: Promise.resolve({ externalId: 'res-1' }) })

    expect(response.status).toBe(409)
    const body = await response.json()
    expect(body.error).toBe('room_already_occupied')
    expect(prisma.stay.upsert).not.toHaveBeenCalled()
  })

  it('updates the lastInboundSyncAt timestamp on success', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.room.upsert).mockResolvedValue({ id: 'room_1', hotelId: 'hotel_1', number: '101' } as never)
    vi.mocked(prisma.stay.findUnique).mockResolvedValue({ id: 'stay_1', roomId: 'room_1' } as never)
    vi.mocked(prisma.stay.upsert).mockResolvedValue({
      id: 'stay_1',
      hotelId: 'hotel_1',
      externalId: 'res-1',
      roomId: 'room_1',
      status: 'active',
    } as never)
    vi.mocked(prisma.guest.upsert).mockResolvedValue({
      id: 'guest_1',
      externalId: 'guest-1',
      accessCode: 'SV-ABCD12',
    } as never)

    await PUT(putRequest('res-1', validPayload), { params: Promise.resolve({ externalId: 'res-1' }) })

    expect(prisma.hotelIntegration.update).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      data: { lastInboundSyncAt: expect.any(Date) },
    })
  })
})
