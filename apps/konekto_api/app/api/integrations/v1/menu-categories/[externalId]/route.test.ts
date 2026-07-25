import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    service: { findUnique: vi.fn(), update: vi.fn(), create: vi.fn(), aggregate: vi.fn() },
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
  return new NextRequest(`http://localhost/api/integrations/v1/menu-categories/${externalId}`, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', authorization: 'Bearer kk_live_test' },
    body: JSON.stringify(body),
  })
}

const validPayload = {
  name: 'Room Service',
  icon: 'room_service',
  description: 'Peça aqui',
  type: 'room_service',
  category: 'Room Service',
}

describe('PUT /api/integrations/v1/menu-categories/[externalId]', () => {
  beforeEach(() => vi.clearAllMocks())

  it('returns 401 when the integration key is invalid', async () => {
    vi.mocked(requireIntegrationAuth).mockRejectedValue(
      new AuthGuardError(new Response(null, { status: 401 }) as never),
    )

    const response = await PUT(putRequest('cat-1', validPayload), { params: Promise.resolve({ externalId: 'cat-1' }) })

    expect(response.status).toBe(401)
  })

  it('rejects an invalid body', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })

    const response = await PUT(putRequest('cat-1', { name: 'x' }), { params: Promise.resolve({ externalId: 'cat-1' }) })

    expect(response.status).toBe(400)
  })

  it('creates a new Service with a slug derived from the name', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.service.findUnique)
      .mockResolvedValueOnce(null) // hotelId_externalId lookup (existing?)
      .mockResolvedValueOnce(null) // hotelId_slug lookup (slug taken?)
    vi.mocked(prisma.service.aggregate).mockResolvedValue({ _max: { position: null } } as never)
    vi.mocked(prisma.service.create).mockResolvedValue({ id: 'svc_1', slug: 'room-service' } as never)

    const response = await PUT(putRequest('cat-1', validPayload), { params: Promise.resolve({ externalId: 'cat-1' }) })

    expect(response.status).toBe(201)
    expect(prisma.service.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ externalId: 'cat-1', slug: 'room-service' }) }),
    )
  })

  it('returns 409 when the derived slug is already taken by another service', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.service.findUnique)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'svc_other', slug: 'room-service' } as never)

    const response = await PUT(putRequest('cat-1', validPayload), { params: Promise.resolve({ externalId: 'cat-1' }) })

    expect(response.status).toBe(409)
    expect(prisma.service.create).not.toHaveBeenCalled()
  })

  it('updates an existing Service by externalId without touching its slug/type', async () => {
    vi.mocked(requireIntegrationAuth).mockResolvedValue({ hotelId: 'hotel_1' })
    vi.mocked(prisma.service.findUnique).mockResolvedValueOnce({
      id: 'svc_1',
      hotelId: 'hotel_1',
      externalId: 'cat-1',
      slug: 'room-service',
      enabled: true,
    } as never)
    vi.mocked(prisma.service.update).mockResolvedValue({ id: 'svc_1' } as never)

    const response = await PUT(putRequest('cat-1', validPayload), { params: Promise.resolve({ externalId: 'cat-1' }) })

    expect(response.status).toBe(200)
    const updateCall = vi.mocked(prisma.service.update).mock.calls[0][0]
    expect(updateCall.where).toEqual({ id: 'svc_1' })
    expect('slug' in updateCall.data).toBe(false)
    expect('type' in updateCall.data).toBe(false)
  })
})
