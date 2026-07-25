import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotel: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    hotelSubscription: {
      findUnique: vi.fn(),
    },
  },
}))

import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { GET, PATCH } from './route'

const baseConfig = {
  hotelInfo: { name: 'Hotel 1', logoUrl: '' },
  colorPalette: { primary: '#000000' },
  infra: 'verde_pousada',
}

function patchRequest(hotelId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}`, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  })
}

describe('GET /api/hotels/[hotelId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns the config blob plus plan and allowedTemplates', async () => {
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'premium' } as never)

    const response = await GET(new NextRequest('http://localhost/api/hotels/hotel_1'), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body).toMatchObject(baseConfig)
    expect(body.plan).toBe('premium')
    expect(body.allowedTemplates).toEqual(['aura', 'bosque', 'elite', 'pulse', 'horizon'])
  })

  it('falls back to the essential plan when the hotel has no subscription row', async () => {
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)

    const response = await GET(new NextRequest('http://localhost/api/hotels/hotel_1'), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    const body = await response.json()
    expect(body.plan).toBe('essential')
    expect(body.allowedTemplates).toEqual(['aura', 'bosque'])
  })

  it('returns 404 when the hotel does not exist', async () => {
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue(null)

    const response = await GET(new NextRequest('http://localhost/api/hotels/unknown'), {
      params: Promise.resolve({ hotelId: 'unknown' }),
    })

    expect(response.status).toBe(404)
  })
})

describe('PATCH /api/hotels/[hotelId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects requests without a staff token', async () => {
    const response = await PATCH(patchRequest('hotel_1', null, { template: 'aura' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(401)
  })

  it('rejects a gerente from a different hotel', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_2', role: 'gerente', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'aura' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('rejects a recepcao token (only gerente can patch hotel config)', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'aura' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('merges the patch into the existing config without touching untouched keys', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotel.update).mockImplementation(
      (async (args: { data: { config: unknown } }) => ({ id: 'hotel_1', config: args.data.config })) as never,
    )

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'aura' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.template).toBe('aura')
    expect(body.hotelInfo).toEqual(baseConfig.hotelInfo)
  })

  it('returns 404 when patching a hotel that does not exist', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue(null)

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'aura' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(404)
  })

  it('rejects an unknown template value', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'not_a_real_template' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('rejects an essential-plan hotel choosing a premium-only template', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'essential' } as never)

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'elite' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
    expect(await response.json()).toEqual({ error: 'template_not_allowed_for_plan' })
  })

  it('allows an essential-plan hotel to choose an essential template', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'essential' } as never)
    vi.mocked(prisma.hotel.update).mockImplementation(
      (async (args: { data: { config: unknown } }) => ({ id: 'hotel_1', config: args.data.config })) as never,
    )

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'bosque' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    expect((await response.json()).template).toBe('bosque')
  })

  it('allows a premium-plan hotel to choose an elite template', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({ plan: 'premium' } as never)
    vi.mocked(prisma.hotel.update).mockImplementation(
      (async (args: { data: { config: unknown } }) => ({ id: 'hotel_1', config: args.data.config })) as never,
    )

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'elite' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    expect((await response.json()).template).toBe('elite')
  })

  it('falls back to the essential plan when the hotel has no subscription row', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)

    const response = await PATCH(patchRequest('hotel_1', token, { template: 'pulse' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })
})
