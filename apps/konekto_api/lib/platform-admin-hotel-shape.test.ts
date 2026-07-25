import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    hotelSubscription: { findUnique: vi.fn() },
    guest: { count: vi.fn() },
    hotelIntegration: { findUnique: vi.fn() },
    platformSupportMessage: { count: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { buildHotelOverview } from './platform-admin-hotel-shape'

const baseHotel = {
  id: 'hotel_1',
  config: { hotelInfo: { name: 'Amara Bay', address: 'Rua das Palmeiras, 120' } },
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
}

describe('buildHotelOverview', () => {
  beforeEach(() => vi.clearAllMocks())

  it('reads name/address from the config JSON blob', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.guest.count).mockResolvedValue(0)
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview(baseHotel)

    expect(overview.name).toBe('Amara Bay')
    expect(overview.address).toBe('Rua das Palmeiras, 120')
  })

  it('falls back to the hotelId as name when config has no hotelInfo.name', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.guest.count).mockResolvedValue(0)
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview({ id: 'hotel_2', config: {}, createdAt: new Date() })

    expect(overview.name).toBe('hotel_2')
    expect(overview.address).toBeNull()
  })

  it('returns subscription: null when no HotelSubscription row exists yet', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.guest.count).mockResolvedValue(3)
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview(baseHotel)

    expect(overview.subscription).toBeNull()
    expect(overview.activeGuestCount).toBe(3)
  })

  it('defaults to the essential preset (core + basic hospitalidade modules, no premium extras) when no subscription row exists', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.guest.count).mockResolvedValue(0)
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview(baseHotel)

    expect(overview.allowedModules).toContain('room_service')
    expect(overview.allowedModules).not.toContain('digital_wallet')
    expect(overview.extraModules).toEqual([])
  })

  it('surfaces the subscription plan and its preset modules when a subscription row exists', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue({
      planName: 'Premium',
      monthlyAmount: 499,
      status: 'active',
      paymentStatus: 'em_dia',
      notes: null,
      plan: 'premium',
      presetId: 'premium',
    } as never)
    vi.mocked(prisma.guest.count).mockResolvedValue(0)
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview(baseHotel)

    expect(overview.subscription?.plan).toBe('premium')
    expect(overview.subscription?.presetId).toBe('premium')
    expect(overview.allowedModules).toContain('loyalty')
    expect(overview.allowedModules).toContain('digital_wallet')
  })

  it('only surfaces courtesy extras in extraModules, filtering out unknown/stale module ids', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.guest.count).mockResolvedValue(0)
    vi.mocked(prisma.hotelIntegration.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview({
      ...baseHotel,
      config: { ...baseHotel.config, extraModules: ['interactive_map', 'not_a_real_module'] },
    })

    expect(overview.extraModules).toEqual(['interactive_map'])
  })

  it('never leaks apiKeyHash/webhookSecret even though HotelIntegration has them', async () => {
    vi.mocked(prisma.hotelSubscription.findUnique).mockResolvedValue(null)
    vi.mocked(prisma.guest.count).mockResolvedValue(0)
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
      lastOutboundError: null,
    } as never)
    vi.mocked(prisma.platformSupportMessage.count).mockResolvedValue(0)

    const overview = await buildHotelOverview(baseHotel)

    expect(overview.integration.configured).toBe(true)
    expect(JSON.stringify(overview)).not.toContain('secret-hash')
    expect(JSON.stringify(overview)).not.toContain('secret-webhook')
  })
})
