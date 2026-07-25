import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotelIntegration: {
      findUnique: vi.fn(),
    },
    guest: {
      findUnique: vi.fn(),
    },
  },
}))

vi.mock('@/lib/stay-expiration', () => ({
  expireStay: vi.fn(),
}))

import { prisma } from '@/lib/prisma'
import { expireStay } from '@/lib/stay-expiration'
import { requireStaffRole, requireGuestAuth, requireIntegrationAuth, requirePlatformAdmin, AuthGuardError } from './auth-guard'
import { signStaffToken } from './jwt'
import { signGuestToken } from './guest-auth'
import { signPlatformAdminToken } from './platform-auth'
import { hashApiKey } from './integration-keys'

function requestWithAuth(header?: string): NextRequest {
  return new NextRequest('http://localhost/api/test', {
    headers: header ? { authorization: header } : {},
  })
}

describe('requireStaffRole', () => {
  it('throws a 401 when there is no Authorization header', async () => {
    await expect(requireStaffRole(requestWithAuth(), ['gerente'])).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
  })

  it('throws a 401 when the token is invalid', async () => {
    await expect(requireStaffRole(requestWithAuth('Bearer not-a-real-token'), ['gerente'])).rejects.toSatisfy(
      (error: unknown) => {
        expect(error).toBeInstanceOf(AuthGuardError)
        expect((error as AuthGuardError).response.status).toBe(401)
        return true
      },
    )
  })

  it('throws a 403 when the role is not in the allowed list', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    await expect(requireStaffRole(requestWithAuth(`Bearer ${token}`), ['gerente'])).rejects.toSatisfy(
      (error: unknown) => {
        expect(error).toBeInstanceOf(AuthGuardError)
        expect((error as AuthGuardError).response.status).toBe(403)
        return true
      },
    )
  })

  it('returns the payload when the token is valid and the role is allowed', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })

    const payload = await requireStaffRole(requestWithAuth(`Bearer ${token}`), ['gerente', 'recepcao'])

    expect(payload.sub).toBe('s1')
    expect(payload.role).toBe('gerente')
  })
})

describe('requireGuestAuth', () => {
  beforeEach(() => vi.clearAllMocks())

  async function guestToken() {
    return signGuestToken({ sub: 'g1', hotelId: 'hotel_1', firstName: 'A', lastName: 'B', roomNumber: '101' })
  }

  it('throws a 401 when there is no Authorization header', async () => {
    await expect(requireGuestAuth(requestWithAuth())).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
  })

  it('throws a 401 when the guest no longer exists (deleted/never existed)', async () => {
    const token = await guestToken()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue(null)

    await expect(requireGuestAuth(requestWithAuth(`Bearer ${token}`))).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
  })

  it('throws a 401 when the guest was manually revoked, even with a still-valid token', async () => {
    const token = await guestToken()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({
      id: 'g1',
      stayId: 'stay_1',
      status: 'revoked',
      stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000) },
    } as never)

    await expect(requireGuestAuth(requestWithAuth(`Bearer ${token}`))).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
    expect(expireStay).not.toHaveBeenCalled()
  })

  it('expires the stay and throws a 401 when checkOutDate has already passed but the stay is still active', async () => {
    const token = await guestToken()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({
      id: 'g1',
      stayId: 'stay_1',
      status: 'active',
      stay: { status: 'active', checkOutDate: new Date(Date.now() - 86400000) },
    } as never)

    await expect(requireGuestAuth(requestWithAuth(`Bearer ${token}`))).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
    expect(expireStay).toHaveBeenCalledWith('stay_1')
  })

  it('returns the payload when the guest is active and the stay is not overdue', async () => {
    const token = await guestToken()
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({
      id: 'g1',
      stayId: 'stay_1',
      status: 'active',
      stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000) },
    } as never)

    const payload = await requireGuestAuth(requestWithAuth(`Bearer ${token}`))

    expect(payload.sub).toBe('g1')
    expect(payload.roomNumber).toBe('101')
    expect(expireStay).not.toHaveBeenCalled()
  })
})

describe('requireIntegrationAuth', () => {
  beforeEach(() => vi.clearAllMocks())

  it('throws a 401 when there is no Authorization header', async () => {
    await expect(requireIntegrationAuth(requestWithAuth())).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
  })

  it('throws a 401 when the key does not match any hotel', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)

    await expect(requireIntegrationAuth(requestWithAuth('Bearer kk_live_unknown'))).rejects.toSatisfy(
      (error: unknown) => {
        expect(error).toBeInstanceOf(AuthGuardError)
        expect((error as AuthGuardError).response.status).toBe(401)
        return true
      },
    )
  })

  it('throws a 401 when the integration is disabled', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({ hotelId: 'hotel_1', enabled: false } as never)

    await expect(requireIntegrationAuth(requestWithAuth('Bearer kk_live_disabled'))).rejects.toSatisfy(
      (error: unknown) => {
        expect(error).toBeInstanceOf(AuthGuardError)
        expect((error as AuthGuardError).response.status).toBe(401)
        return true
      },
    )
  })

  it('resolves the hotelId from the key when it matches an enabled integration', async () => {
    const key = 'kk_live_valid'
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({ hotelId: 'hotel_1', enabled: true } as never)

    const result = await requireIntegrationAuth(requestWithAuth(`Bearer ${key}`))

    expect(result.hotelId).toBe('hotel_1')
    expect(prisma.hotelIntegration.findUnique).toHaveBeenCalledWith({ where: { apiKeyHash: hashApiKey(key) } })
  })
})

describe('requirePlatformAdmin', () => {
  it('throws a 401 when there is no Authorization header', async () => {
    await expect(requirePlatformAdmin(requestWithAuth())).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
  })

  it('throws a 401 when the token is invalid', async () => {
    await expect(requirePlatformAdmin(requestWithAuth('Bearer not-a-real-token'))).rejects.toSatisfy(
      (error: unknown) => {
        expect(error).toBeInstanceOf(AuthGuardError)
        expect((error as AuthGuardError).response.status).toBe(401)
        return true
      },
    )
  })

  it('throws a 401 for a valid STAFF token (different secret + missing type discriminator)', async () => {
    const staffToken = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })

    await expect(requirePlatformAdmin(requestWithAuth(`Bearer ${staffToken}`))).rejects.toSatisfy((error: unknown) => {
      expect(error).toBeInstanceOf(AuthGuardError)
      expect((error as AuthGuardError).response.status).toBe(401)
      return true
    })
  })

  it('returns the payload when the platform-admin token is valid', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })

    const payload = await requirePlatformAdmin(requestWithAuth(`Bearer ${token}`))

    expect(payload.sub).toBe('admin_1')
    expect(payload.type).toBe('platform_admin')
  })
})
