import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotelIntegration: {
      findUnique: vi.fn(),
      upsert: vi.fn(),
      update: vi.fn(),
    },
  },
}))

// Sem isso, a validação de webhook faria uma resolução de DNS de verdade
// em todo teste que salva uma URL — mocka pra manter o teste isolado e
// determinístico; o comportamento do guard em si é coberto por
// `lib/ssrf-guard.test.ts`.
vi.mock('@/lib/ssrf-guard', () => ({
  isSafeHost: vi.fn().mockResolvedValue(true),
  safeParseUrl: vi.fn((value: string) => {
    try {
      return new URL(value)
    } catch {
      return null
    }
  }),
}))

import { prisma } from '@/lib/prisma'
import { isSafeHost } from '@/lib/ssrf-guard'
import { signStaffToken } from '@/lib/jwt'
import { GET, POST, PATCH } from './route'

function makeRequest(method: string, hotelId: string, token: string | null, body?: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/integration`, {
    method,
    headers: {
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('/api/hotels/[hotelId]/integration', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a recepcao token', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await GET(makeRequest('GET', 'hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(403)
  })

  it('GET returns configured: false when no integration exists yet', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)

    const response = await GET(makeRequest('GET', 'hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.configured).toBe(false)
  })

  it('GET never leaks the api key hash or webhook secret', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      apiKeyHash: 'secret-hash',
      apiKeyPrefix: 'kk_live_a1b2',
      webhookUrl: 'https://example.com/hook',
      webhookSecret: 'secret-webhook',
      enabled: true,
      lastInboundSyncAt: null,
      lastOutboundAt: null,
      lastOutboundOk: null,
    } as never)

    const response = await GET(makeRequest('GET', 'hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })
    const body = await response.json()

    expect(body.apiKeyPrefix).toBe('kk_live_a1b2')
    expect(JSON.stringify(body)).not.toContain('secret-hash')
    expect(JSON.stringify(body)).not.toContain('secret-webhook')
  })

  it('POST rotate_key returns the plain key once and persists only its hash', async () => {
    const token = await gerenteToken()
    const upsertMock = async (args: unknown) => {
      const create = (args as { create: Record<string, unknown> }).create
      return {
        ...create,
        lastInboundSyncAt: null,
        lastOutboundAt: null,
        lastOutboundOk: null,
      }
    }
    vi.mocked(prisma.hotelIntegration.upsert).mockImplementation(upsertMock as unknown as typeof prisma.hotelIntegration.upsert)

    const response = await POST(makeRequest('POST', 'hotel_1', token, { action: 'rotate_key' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.apiKey).toMatch(/^kk_live_/)
    expect(body.apiKeyPrefix).toBe(body.apiKey.slice(0, body.apiKeyPrefix.length))

    const upsertCall = vi.mocked(prisma.hotelIntegration.upsert).mock.calls[0][0]
    expect(JSON.stringify(upsertCall)).not.toContain(body.apiKey)
  })

  it('POST rejects an invalid body', async () => {
    const token = await gerenteToken()

    const response = await POST(makeRequest('POST', 'hotel_1', token, { action: 'wrong' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('PATCH returns 404 when the integration was never configured', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)

    const response = await PATCH(makeRequest('PATCH', 'hotel_1', token, { webhookUrl: 'https://example.com/hook' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(404)
  })

  it('PATCH updates the webhook URL when the integration exists', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({ hotelId: 'hotel_1' } as never)
    vi.mocked(prisma.hotelIntegration.update).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: 'https://example.com/hook',
    } as never)

    const response = await PATCH(makeRequest('PATCH', 'hotel_1', token, { webhookUrl: 'https://example.com/hook' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.webhookUrl).toBe('https://example.com/hook')
  })

  it('PATCH rejects an invalid URL', async () => {
    const token = await gerenteToken()

    const response = await PATCH(makeRequest('PATCH', 'hotel_1', token, { webhookUrl: 'not-a-url' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('PATCH rejects a webhook URL that resolves to a private/unsafe host (SSRF guard)', async () => {
    const token = await gerenteToken()
    vi.mocked(isSafeHost).mockResolvedValueOnce(false)

    const response = await PATCH(
      makeRequest('PATCH', 'hotel_1', token, { webhookUrl: 'http://169.254.169.254/latest/meta-data' }),
      { params: Promise.resolve({ hotelId: 'hotel_1' }) },
    )

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBe('unsafe_webhook_url')
    expect(prisma.hotelIntegration.update).not.toHaveBeenCalled()
  })
})
