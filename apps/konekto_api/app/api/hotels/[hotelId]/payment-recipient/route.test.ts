import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotelPaymentAccount: {
      findUnique: vi.fn(),
      upsert: vi.fn(),
    },
  },
}))

vi.mock('@/lib/pagarme', () => ({
  getRecipient: vi.fn(),
  PagarmeError: class PagarmeError extends Error {
    constructor(
      public status: number,
      public body: unknown,
    ) {
      super('PagarmeError')
    }
  },
}))

import { prisma } from '@/lib/prisma'
import { getRecipient } from '@/lib/pagarme'
import { signStaffToken } from '@/lib/jwt'
import { GET, POST } from './route'

function postRequest(hotelId: string, token: string | null, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/payment-recipient`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  })
}

function getRequest(hotelId: string, token: string | null): NextRequest {
  return new NextRequest(`http://localhost/api/hotels/${hotelId}/payment-recipient`, {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  })
}

async function gerenteToken(hotelId = 'hotel_1') {
  return signStaffToken({ sub: 's1', hotelId, role: 'gerente', email: 'a@b.com', name: 'A' })
}

describe('/api/hotels/[hotelId]/payment-recipient', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rejects a recepcao token (only gerente can configure payments)', async () => {
    const token = await signStaffToken({ sub: 's1', hotelId: 'hotel_1', role: 'recepcao', email: 'a@b.com', name: 'A' })

    const response = await POST(postRequest('hotel_1', token, { recipientId: 'rp_1' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(403)
  })

  it('rejects an invalid body', async () => {
    const token = await gerenteToken()

    const response = await POST(postRequest('hotel_1', token, { recipientId: '' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
  })

  it('returns recipient_not_found when the Pagar.me recipient does not exist', async () => {
    const token = await gerenteToken()
    vi.mocked(getRecipient).mockRejectedValue(new (await import('@/lib/pagarme')).PagarmeError(404, { message: 'not found' }))

    const response = await POST(postRequest('hotel_1', token, { recipientId: 'rp_missing' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBe('recipient_not_found')
  })

  it('saves the account as verified when Pagar.me reports the recipient as active', async () => {
    const token = await gerenteToken()
    vi.mocked(getRecipient).mockResolvedValue({ id: 'rp_1', status: 'active' })
    vi.mocked(prisma.hotelPaymentAccount.upsert).mockResolvedValue({
      hotelId: 'hotel_1',
      pagarmeRecipientId: 'rp_1',
      status: 'verified',
      pagarmeStatus: 'active',
    } as never)

    const response = await POST(postRequest('hotel_1', token, { recipientId: 'rp_1' }), {
      params: Promise.resolve({ hotelId: 'hotel_1' }),
    })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.status).toBe('verified')
  })

  it('GET returns configured: false when no account exists yet', async () => {
    const token = await gerenteToken()
    vi.mocked(prisma.hotelPaymentAccount.findUnique).mockResolvedValue(null)

    const response = await GET(getRequest('hotel_1', token), { params: Promise.resolve({ hotelId: 'hotel_1' }) })

    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.configured).toBe(false)
  })
})
