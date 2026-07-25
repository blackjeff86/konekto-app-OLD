import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformAdmin: { findUnique: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { signStaffToken } from '@/lib/jwt'
import { GET } from './route'

function getRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/me', {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

describe('GET /api/platform-admin/me', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a token', async () => {
    const response = await GET(getRequest(null))
    expect(response.status).toBe(401)
  })

  it('returns 401 for a staff token (different secret + missing discriminator)', async () => {
    const staffToken = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    const response = await GET(getRequest(staffToken))
    expect(response.status).toBe(401)
  })

  it('returns 401 when the admin no longer exists', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.platformAdmin.findUnique).mockResolvedValue(null)

    const response = await GET(getRequest(token))

    expect(response.status).toBe(401)
    const body = await response.json()
    expect(body.error).toBe('admin_not_found')
  })

  it('returns the admin when the token is valid', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.platformAdmin.findUnique).mockResolvedValue({
      id: 'admin_1',
      email: 'a@konekto.app',
      name: 'Admin',
    } as never)

    const response = await GET(getRequest(token))

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.admin).toEqual({ id: 'admin_1', name: 'Admin', email: 'a@konekto.app' })
  })
})
