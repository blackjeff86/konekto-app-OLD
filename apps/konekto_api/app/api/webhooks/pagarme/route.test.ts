import { NextRequest } from 'next/server'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    stayPayment: { updateMany: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { POST } from './route'

function basicAuthHeader(secret: string): string {
  return `Basic ${Buffer.from(`${secret}:`).toString('base64')}`
}

function webhookRequest(authHeader: string | null, body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/webhooks/pagarme', {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(authHeader ? { authorization: authHeader } : {}) },
    body: JSON.stringify(body),
  })
}

describe('POST /api/webhooks/pagarme', () => {
  const originalSecret = process.env.PAGARME_WEBHOOK_SECRET

  beforeEach(() => {
    vi.clearAllMocks()
    process.env.PAGARME_WEBHOOK_SECRET = 'super-secret'
  })

  afterEach(() => {
    process.env.PAGARME_WEBHOOK_SECRET = originalSecret
  })

  it('rejects a request with no Authorization header', async () => {
    const response = await POST(webhookRequest(null, { type: 'charge.paid', data: { id: 'charge_1' } }))
    expect(response.status).toBe(401)
    expect(prisma.stayPayment.updateMany).not.toHaveBeenCalled()
  })

  it('rejects a request with the wrong secret', async () => {
    const response = await POST(webhookRequest(basicAuthHeader('wrong-secret'), { type: 'charge.paid', data: { id: 'charge_1' } }))
    expect(response.status).toBe(401)
  })

  it('rejects when PAGARME_WEBHOOK_SECRET is not configured, even with a valid-looking header', async () => {
    delete process.env.PAGARME_WEBHOOK_SECRET
    const response = await POST(webhookRequest(basicAuthHeader('super-secret'), { type: 'charge.paid', data: { id: 'charge_1' } }))
    expect(response.status).toBe(401)
  })

  it('rejects a malformed payload', async () => {
    const response = await POST(webhookRequest(basicAuthHeader('super-secret'), { type: 'charge.paid' }))
    expect(response.status).toBe(400)
  })

  it('marks the matching StayPayment as paid on charge.paid', async () => {
    const response = await POST(webhookRequest(basicAuthHeader('super-secret'), { type: 'charge.paid', data: { id: 'charge_1' } }))

    expect(response.status).toBe(200)
    expect(prisma.stayPayment.updateMany).toHaveBeenCalledWith({
      where: { pagarmeChargeId: 'charge_1' },
      data: { status: 'paid' },
    })
  })

  it('marks the matching StayPayment as failed on charge.payment_failed', async () => {
    const response = await POST(webhookRequest(basicAuthHeader('super-secret'), { type: 'charge.payment_failed', data: { id: 'charge_2' } }))

    expect(response.status).toBe(200)
    expect(prisma.stayPayment.updateMany).toHaveBeenCalledWith({
      where: { pagarmeChargeId: 'charge_2' },
      data: { status: 'failed', failureReason: 'charge.payment_failed' },
    })
  })

  it('ignores unrecognized event types without erroring', async () => {
    const response = await POST(webhookRequest(basicAuthHeader('super-secret'), { type: 'order.created', data: { id: 'order_1' } }))

    expect(response.status).toBe(200)
    expect(prisma.stayPayment.updateMany).not.toHaveBeenCalled()
  })
})
