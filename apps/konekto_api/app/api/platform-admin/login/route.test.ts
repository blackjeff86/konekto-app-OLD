import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import bcrypt from 'bcryptjs'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    platformAdmin: { findUnique: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { verifyPlatformAdminToken } from '@/lib/platform-auth'
import { POST } from './route'

function postRequest(body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  })
}

describe('POST /api/platform-admin/login', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects an invalid body', async () => {
    const response = await POST(postRequest({ email: 'not-an-email' }))
    expect(response.status).toBe(400)
  })

  it('returns 401 when the admin does not exist', async () => {
    vi.mocked(prisma.platformAdmin.findUnique).mockResolvedValue(null)

    const response = await POST(postRequest({ email: 'a@konekto.app', password: 'wrong' }))

    expect(response.status).toBe(401)
    const body = await response.json()
    expect(body.error).toBe('invalid_credentials')
  })

  it('returns 401 when the password does not match', async () => {
    const passwordHash = await bcrypt.hash('correct-password', 10)
    vi.mocked(prisma.platformAdmin.findUnique).mockResolvedValue({
      id: 'admin_1',
      email: 'a@konekto.app',
      name: 'Admin',
      passwordHash,
    } as never)

    const response = await POST(postRequest({ email: 'a@konekto.app', password: 'wrong-password' }))

    expect(response.status).toBe(401)
  })

  it('returns a valid platform-admin token on success', async () => {
    const passwordHash = await bcrypt.hash('correct-password', 10)
    vi.mocked(prisma.platformAdmin.findUnique).mockResolvedValue({
      id: 'admin_1',
      email: 'a@konekto.app',
      name: 'Admin',
      passwordHash,
    } as never)

    const response = await POST(postRequest({ email: 'a@konekto.app', password: 'correct-password' }))

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.admin).toEqual({ id: 'admin_1', name: 'Admin', email: 'a@konekto.app' })
    const verified = await verifyPlatformAdminToken(body.token)
    expect(verified.sub).toBe('admin_1')
  })
})
