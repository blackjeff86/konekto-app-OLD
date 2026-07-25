import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotel: {
      findUnique: vi.fn(),
      update: vi.fn(),
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

  it('returns the raw config blob', async () => {
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)

    const response = await GET(new NextRequest('http://localhost/api/hotels/hotel_1'), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    expect(await response.json()).toEqual(baseConfig)
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
    const response = await PATCH(patchRequest('hotel_1', null, { infra: 'amara_bay' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(401)
  })

  it('rejects a gerente from a different hotel', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_2', role: 'gerente', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', token, { infra: 'amara_bay' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('rejects a recepcao token (only gerente can patch hotel config)', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', token, { infra: 'amara_bay' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('rejects an invalid infra value', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })

    const response = await PATCH(patchRequest('hotel_1', token, { infra: 'not_a_real_infra' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('merges the patch into the existing config without touching untouched keys', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue({ id: 'hotel_1', config: baseConfig } as never)
    vi.mocked(prisma.hotel.update).mockImplementation(
      (async (args: { data: { config: unknown } }) => ({ id: 'hotel_1', config: args.data.config })) as never,
    )

    const response = await PATCH(patchRequest('hotel_1', token, { infra: 'amara_bay' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.infra).toBe('amara_bay')
    expect(body.hotelInfo).toEqual(baseConfig.hotelInfo)
  })

  it('returns 404 when patching a hotel that does not exist', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'gerente', email: 'a@b.com', name: 'A' })
    vi.mocked(prisma.hotel.findUnique).mockResolvedValue(null)

    const response = await PATCH(patchRequest('hotel_1', token, { infra: 'amara_bay' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(404)
  })
})
