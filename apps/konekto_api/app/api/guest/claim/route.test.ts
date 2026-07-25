import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    guest: { findUnique: vi.fn() },
    hotelContent: { findUnique: vi.fn() },
  },
}))

vi.mock('@/lib/stay-expiration', () => ({
  expireStay: vi.fn(),
}))

import { prisma } from '@/lib/prisma'
import { expireStay } from '@/lib/stay-expiration'
import { POST } from './route'

function postRequest(body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/guest/claim', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  })
}

const baseGuest = {
  id: 'g1',
  hotelId: 'hotel_1',
  stayId: 'stay_1',
  firstName: 'A',
  lastName: 'B',
  wifiPassword: null,
  stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000), room: { number: '101' } },
}

describe('POST /api/guest/claim', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 404 when the access code does not match any guest', async () => {
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(null)

    const response = await POST(postRequest({ code: 'UNKNOWN' }))

    expect(response.status).toBe(404)
  })

  it('rejects a guest that was manually revoked', async () => {
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({ ...baseGuest, status: 'revoked' } as never)

    const response = await POST(postRequest({ code: 'HOTEL1-ABC123' }))

    expect(response.status).toBe(403)
    expect(expireStay).not.toHaveBeenCalled()
  })

  it('expires the stay and rejects login when checkOutDate has already passed', async () => {
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({
      ...baseGuest,
      status: 'active',
      stay: { ...baseGuest.stay, checkOutDate: new Date(Date.now() - 86400000) },
    } as never)

    const response = await POST(postRequest({ code: 'HOTEL1-ABC123' }))

    expect(response.status).toBe(403)
    const body = await response.json()
    expect(body.error).toBe('access_revoked')
    expect(expireStay).toHaveBeenCalledWith('stay_1')
  })

  it('logs in successfully when the guest is active and the stay is not overdue', async () => {
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({ ...baseGuest, status: 'active' } as never)
    vi.mocked(prisma.hotelContent.findUnique).mockResolvedValue(null)

    const response = await POST(postRequest({ code: 'HOTEL1-ABC123' }))

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.token).toBeTruthy()
    expect(expireStay).not.toHaveBeenCalled()
  })
})
