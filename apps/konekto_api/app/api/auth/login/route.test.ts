import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import bcrypt from 'bcryptjs'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    staff: { findUnique: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { verifyStaffToken } from '@/lib/jwt'
import { __resetRateLimitStore } from '@/lib/rate-limit'
import { CORRELATION_ID_HEADER } from '@/lib/request-context'
import { POST } from './route'

function postRequest(body: unknown, ip = '203.0.113.10'): NextRequest {
  return new NextRequest('http://localhost/api/auth/login', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-forwarded-for': ip,
    },
    body: JSON.stringify(body),
  })
}

describe('POST /api/auth/login', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    __resetRateLimitStore()
  })

  it('rejects an invalid body', async () => {
    const response = await POST(postRequest({ email: 'not-an-email' }))
    expect(response.status).toBe(400)
  })

  it('returns 401 when the staff user does not exist', async () => {
    vi.mocked(prisma.staff.findUnique).mockResolvedValue(null)

    const response = await POST(postRequest({ email: 'staff@hotel.com', password: 'wrong' }))

    expect(response.status).toBe(401)
    const body = await response.json()
    expect(body.error).toBe('invalid_credentials')
  })

  it('returns a valid staff token on success', async () => {
    const passwordHash = await bcrypt.hash('correct-password', 10)
    vi.mocked(prisma.staff.findUnique).mockResolvedValue({
      id: 'staff_1',
      hotelId: 'hotel_1',
      role: 'gerente',
      email: 'staff@hotel.com',
      name: 'Staff',
      passwordHash,
    } as never)

    const response = await POST(postRequest({ email: 'staff@hotel.com', password: 'correct-password' }))

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.staff).toEqual({
      id: 'staff_1',
      hotelId: 'hotel_1',
      role: 'gerente',
      name: 'Staff',
      email: 'staff@hotel.com',
    })
    expect(response.headers.get(CORRELATION_ID_HEADER)).toBeTruthy()
    const verified = await verifyStaffToken(body.token)
    expect(verified.sub).toBe('staff_1')
  })

  it('returns 429 after repeated attempts from the same IP', async () => {
    vi.mocked(prisma.staff.findUnique).mockResolvedValue(null)

    for (let i = 0; i < 10; i++) {
      const response = await POST(postRequest({ email: 'staff@hotel.com', password: 'wrong' }))
      expect(response.status).toBe(401)
    }

    const blocked = await POST(postRequest({ email: 'staff@hotel.com', password: 'wrong' }))
    expect(blocked.status).toBe(429)
  })
})
