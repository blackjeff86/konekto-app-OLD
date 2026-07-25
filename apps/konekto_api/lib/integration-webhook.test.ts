import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotelIntegration: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
  },
}))

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
import { dispatchOrderWebhook, type OrderWebhookOrder } from './integration-webhook'

const order: OrderWebhookOrder = {
  id: 'order_1',
  hotelId: 'hotel_1',
  guestId: 'guest_1',
  serviceId: 'svc_1',
  serviceItemId: 'item_1',
  itemName: 'Club Sandwich',
  price: 39.9,
  quantity: 1,
  note: null,
  scheduledFor: null,
  createdAt: new Date('2026-07-19T12:00:00.000Z'),
}

describe('dispatchOrderWebhook', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(isSafeHost).mockResolvedValue(true)
    vi.stubGlobal('fetch', vi.fn())
  })

  it('does nothing when the hotel has no integration configured', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)

    await dispatchOrderWebhook(order, 'hotel_1')

    expect(fetch).not.toHaveBeenCalled()
  })

  it('does nothing when the integration has no webhookUrl set', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: null,
      webhookSecret: 'secret',
    } as never)

    await dispatchOrderWebhook(order, 'hotel_1')

    expect(fetch).not.toHaveBeenCalled()
  })

  it('signs the payload and posts it when a webhookUrl is configured', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: 'https://example.com/hook',
      webhookSecret: 'secret',
    } as never)
    vi.mocked(fetch).mockResolvedValue(new Response(null, { status: 200 }))

    await dispatchOrderWebhook(order, 'hotel_1')

    expect(fetch).toHaveBeenCalledTimes(1)
    const [url, init] = vi.mocked(fetch).mock.calls[0]
    expect(url).toBe('https://example.com/hook')
    expect((init?.headers as Record<string, string>)['X-Konekto-Signature']).toMatch(/^sha256=[0-9a-f]{64}$/)
    expect(prisma.hotelIntegration.update).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      data: { lastOutboundAt: expect.any(Date), lastOutboundOk: true, lastOutboundError: null },
    })
  })

  it('records a failure and never throws when the destination returns a non-2xx status', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: 'https://example.com/hook',
      webhookSecret: 'secret',
    } as never)
    vi.mocked(fetch).mockResolvedValue(new Response(null, { status: 500 }))

    await expect(dispatchOrderWebhook(order, 'hotel_1')).resolves.toBeUndefined()

    expect(prisma.hotelIntegration.update).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      data: { lastOutboundAt: expect.any(Date), lastOutboundOk: false, lastOutboundError: 'HTTP 500' },
    })
  })

  it('never calls fetch and records unsafe_webhook_url when the host resolves to a private/unsafe address', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: 'http://169.254.169.254/latest/meta-data',
      webhookSecret: 'secret',
    } as never)
    vi.mocked(isSafeHost).mockResolvedValue(false)

    await dispatchOrderWebhook(order, 'hotel_1')

    expect(fetch).not.toHaveBeenCalled()
    expect(prisma.hotelIntegration.update).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      data: { lastOutboundAt: expect.any(Date), lastOutboundOk: false, lastOutboundError: 'unsafe_webhook_url' },
    })
  })

  it('re-validates the host on redirect and blocks the hop if it points to an unsafe address', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: 'https://example.com/hook',
      webhookSecret: 'secret',
    } as never)
    vi.mocked(isSafeHost).mockResolvedValueOnce(true).mockResolvedValueOnce(false)
    vi.mocked(fetch).mockResolvedValue(
      new Response(null, { status: 302, headers: { location: 'http://169.254.169.254/latest/meta-data' } }),
    )

    await dispatchOrderWebhook(order, 'hotel_1')

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(prisma.hotelIntegration.update).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      data: { lastOutboundAt: expect.any(Date), lastOutboundOk: false, lastOutboundError: 'unsafe_webhook_url' },
    })
  })

  it('records a failure and never throws when the fetch itself rejects (network error/timeout)', async () => {
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue({
      hotelId: 'hotel_1',
      webhookUrl: 'https://example.com/hook',
      webhookSecret: 'secret',
    } as never)
    vi.mocked(fetch).mockRejectedValue(new Error('timeout'))

    await expect(dispatchOrderWebhook(order, 'hotel_1')).resolves.toBeUndefined()

    expect(prisma.hotelIntegration.update).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1' },
      data: { lastOutboundAt: expect.any(Date), lastOutboundOk: false, lastOutboundError: 'timeout' },
    })
  })
})
