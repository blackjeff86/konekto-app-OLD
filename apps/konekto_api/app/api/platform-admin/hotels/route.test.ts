import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import bcrypt from 'bcryptjs'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotel: { findMany: vi.fn() },
    staff: { findUnique: vi.fn() },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/platform-admin-hotel-shape', () => ({
  buildHotelOverview: vi.fn(async (hotel: { id: string }) => ({ hotelId: hotel.id, name: hotel.id })),
}))

import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { GET, POST } from './route'

function getRequest(token: string | null): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/hotels', {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

function postRequest(token: string | null, body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/platform-admin/hotels', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

describe('GET /api/platform-admin/hotels', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid platform-admin token', async () => {
    const response = await GET(getRequest(null))
    expect(response.status).toBe(401)
  })

  it('returns an overview per hotel', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findMany).mockResolvedValue([
      { id: 'hotel_3', config: {}, createdAt: new Date() },
      { id: 'hotel_4', config: {}, createdAt: new Date() },
    ] as never)

    const response = await GET(getRequest(token))

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body).toHaveLength(2)
    expect(body[0].hotelId).toBe('hotel_3')
    expect(body[1].hotelId).toBe('hotel_4')
  })

  it('only queries hotels with kind: client, excluding template installations like Verde Pousada/Amara Bay', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.hotel.findMany).mockResolvedValue([])

    await GET(getRequest(token))

    expect(prisma.hotel.findMany).toHaveBeenCalledWith({ where: { kind: 'client' }, orderBy: { createdAt: 'asc' } })
  })
})

describe('POST /api/platform-admin/hotels', () => {
  const validBody = {
    name: 'Konekto Hotel',
    gerente: { name: 'Maria Gerente', email: 'maria@konektohotel.com' },
  }

  function fakeTx() {
    return {
      hotel: { create: vi.fn().mockResolvedValue({ id: 'new-hotel-id' }) },
      staff: { create: vi.fn().mockResolvedValue({ id: 'staff_1' }) },
      hotelSubscription: { create: vi.fn().mockResolvedValue({ hotelId: 'new-hotel-id' }) },
    }
  }

  beforeEach(() => vi.clearAllMocks())

  it('returns 401 without a valid platform-admin token', async () => {
    const response = await POST(postRequest(null, validBody))
    expect(response.status).toBe(401)
  })

  it('rejects an empty hotel name', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    const response = await POST(postRequest(token, { ...validBody, name: '' }))
    expect(response.status).toBe(400)
    expect(prisma.$transaction).not.toHaveBeenCalled()
  })

  it('rejects an invalid gerente email', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    const response = await POST(
      postRequest(token, { ...validBody, gerente: { name: 'Maria', email: 'not-an-email' } }),
    )
    expect(response.status).toBe(400)
    expect(prisma.$transaction).not.toHaveBeenCalled()
  })

  it('rejects when the gerente email is already in use by another staff account', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.staff.findUnique).mockResolvedValue({ id: 'existing_staff' } as never)

    const response = await POST(postRequest(token, validBody))

    expect(response.status).toBe(409)
    expect(await response.json()).toEqual({ error: 'email_already_in_use' })
    expect(prisma.$transaction).not.toHaveBeenCalled()
  })

  it('creates the hotel and its first gerente atomically, returning a one-time temporary password', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.staff.findUnique).mockResolvedValue(null)
    const tx = fakeTx()
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    const response = await POST(postRequest(token, validBody))

    expect(response.status).toBe(201)
    const body = await response.json()
    expect(body.gerente).toEqual({ name: 'Maria Gerente', email: 'maria@konektohotel.com' })
    expect(typeof body.hotelId).toBe('string')
    expect(typeof body.temporaryPassword).toBe('string')
    expect(body.temporaryPassword.length).toBeGreaterThan(0)

    // O Hotel nunca reaproveita um ID já existente — sempre um novo, gerado
    // no servidor — e todo hotel nasce com `template: aura` por padrão.
    expect(tx.hotel.create).toHaveBeenCalledWith({
      data: {
        id: body.hotelId,
        config: {
          template: 'aura',
          hotelInfo: {
            name: 'Konekto Hotel',
            logoUrl: null,
            address: null,
            promoImages: { carouselEnabled: false, images: [], carouselHeight: 220 },
          },
        },
      },
    })

    // A senha nunca é persistida em texto puro — só o hash, que precisa
    // bater com a senha devolvida na resposta (única vez que ela existe
    // em texto puro).
    const staffCreateCall = tx.staff.create.mock.calls[0][0]
    expect(staffCreateCall.data.hotelId).toBe(body.hotelId)
    expect(staffCreateCall.data.email).toBe('maria@konektohotel.com')
    expect(staffCreateCall.data.role).toBe('gerente')
    expect(staffCreateCall.data.name).toBe('Maria Gerente')
    expect(staffCreateCall.data.passwordHash).not.toBe(body.temporaryPassword)
    await expect(bcrypt.compare(body.temporaryPassword, staffCreateCall.data.passwordHash)).resolves.toBe(true)

    // Sem `plan` no body, o hotel nasce no plano mais restrito (essential)
    // — nunca assume um plano pago por omissão.
    expect(tx.hotelSubscription.create).toHaveBeenCalledWith({
      data: { hotelId: body.hotelId, plan: 'essential', planName: 'Essential', status: 'trial' },
    })
  })

  it('creates the hotel subscription with the requested plan', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.staff.findUnique).mockResolvedValue(null)
    const tx = fakeTx()
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    const response = await POST(postRequest(token, { ...validBody, plan: 'premium' }))
    const body = await response.json()

    expect(tx.hotelSubscription.create).toHaveBeenCalledWith({
      data: { hotelId: body.hotelId, plan: 'premium', planName: 'Premium', status: 'trial' },
    })
  })

  it('lowercases and trims the gerente email before checking/creating', async () => {
    const token = await signPlatformAdminToken({ sub: 'admin_1', email: 'a@konekto.app', name: 'Admin' })
    vi.mocked(prisma.staff.findUnique).mockResolvedValue(null)
    const tx = fakeTx()
    vi.mocked(prisma.$transaction).mockImplementation(((callback: (tx: unknown) => unknown) => callback(tx)) as never)

    await POST(
      postRequest(token, { ...validBody, gerente: { name: 'Maria', email: '  Maria@KonektoHotel.com  ' } }),
    )

    expect(prisma.staff.findUnique).toHaveBeenCalledWith({ where: { email: 'maria@konektohotel.com' } })
    expect(tx.staff.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ email: 'maria@konektohotel.com' }) }),
    )
  })
})
