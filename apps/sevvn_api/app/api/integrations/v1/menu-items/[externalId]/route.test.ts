import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn() },
    serviceItem: { findUnique: vi.fn(), update: vi.fn(), create: vi.fn(), aggregate: vi.fn() },
    hotelIntegration: { update: vi.fn() },
  },
}))

vi.mock('@/lib/auth-guard', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/auth-guard')>()
  return { ...actual, requireIntegrationAuth: vi.fn() }
})

vi.mock('@/lib/translate', () => ({ autoTranslateOrNull: vi.fn().mockResolvedValue(null) }))

import { prisma } from '@/lib/prisma'
import { requireIntegrationAuth, AuthGuardError } from '@/lib/auth-guard'
import { PUT } from './route'

function putRequest(externalId: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/integrations/v1/menu-items/${externalId}`, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', authorization: 'Bearer kk_live_test' },
    body: JSON.stringify(body),
  })
}

const validPayload = {
  categoryExternalId: 'cat-1',
  name: 'Club Sandwich',
  description: 'Pão, frango, bacon',
  price: 39.9,
}

describe('PUT /api/integrations/v1/menu-items/[externalId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 when the integration key is invalid', async () => {
    vi.mocked(requireIntegrationAuth).mockRejectedValue(
      new AuthGuardError(new Response(null, { status: 401 }) as never),
    )

    const response = await PUT(putRequest('item-1', validPayload), { params: Promise.resolve({ externalId: 'item-1' }) })

    expect(response.status).toBe(401)
  })

  it('returns 404 when the referenced category has not been synced yet', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.service.findUnique).mockResolvedValue(null)

    const response = await PUT(putRequest('item-1', validPayload), { params: Promise.resolve({ externalId: 'item-1' }) })

    expect(response.status).toBe(404)
    const body = await response.json()
    expect(body.error).toBe('category_not_found')
  })

  it('creates a new ServiceItem under the resolved category', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.serviceItem.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.serviceItem.aggregate).mockResolvedValue({ _max: { position: null } } as never)
    vi.mocked(prisma.serviceItem.create).mockResolvedValue({ id: 'item_1' } as never)

    const response = await PUT(putRequest('item-1', validPayload), { params: Promise.resolve({ externalId: 'item-1' }) })

    expect(response.status).toBe(201)
    expect(prisma.serviceItem.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ serviceId: 'svc_1', externalId: 'item-1', price: 39.9 }) }),
    )
  })

  it('updates an existing ServiceItem by externalId', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.service.findUnique).mockResolvedValue({ id: 'svc_1', hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.serviceItem.findUnique).mockResolvedValue({ id: 'item_1', serviceId: 'svc_1' } as never)
    vi.mocked(prisma.serviceItem.update).mockResolvedValue({ id: 'item_1' } as never)

    const response = await PUT(putRequest('item-1', validPayload), { params: Promise.resolve({ externalId: 'item-1' }) })

    expect(response.status).toBe(200)
    expect(prisma.serviceItem.create).not.toHaveBeenCalled()
    expect(prisma.serviceItem.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'item_1' } }),
    )
  })
})
