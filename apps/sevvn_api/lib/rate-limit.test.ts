import { NextRequest } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { __resetRateLimitStore, enforceRateLimit } from './rate-limit'

function request(ip = '203.0.113.10') {
  return new NextRequest('http://localhost/api/test', {
    headers: { 'x-forwarded-for': ip },
  })
}

describe('enforceRateLimit', () => {
  beforeEach(() => {
    vi.useRealTimers()
    __resetRateLimitStore()
  })

  it('allows requests up to the configured limit within the window', () => {
    const rule = { bucket: 'guest-claim', max: 2, windowMs: 60_000 }

    expect(enforceRateLimit(request(), rule)).toBeNull()
    expect(enforceRateLimit(request(), rule)).toBeNull()
  })

  it('returns 429 after the limit is exceeded', async () => {
    const rule = { bucket: 'guest-claim', max: 1, windowMs: 60_000 }

    expect(enforceRateLimit(request(), rule)).toBeNull()
    const response = enforceRateLimit(request(), rule)

    expect(response?.status).toBe(429)
    expect(await response?.json()).toMatchObject({ error: 'rate_limited', limit: 1, windowMs: 60_000 })
    expect(response?.headers.get('Retry-After')).toBeTruthy()
  })

  it('tracks buckets independently', () => {
    const authRule = { bucket: 'staff-login', max: 1, windowMs: 60_000 }
    const imageRule = { bucket: 'image-proxy', max: 1, windowMs: 60_000 }

    expect(enforceRateLimit(request(), authRule)).toBeNull()
    expect(enforceRateLimit(request(), imageRule)).toBeNull()
  })

  it('resets the counter after the time window elapses', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-07-26T12:00:00.000Z'))

    const rule = { bucket: 'public-hotels', max: 1, windowMs: 60_000 }
    expect(enforceRateLimit(request(), rule)).toBeNull()
    expect(enforceRateLimit(request(), rule)?.status).toBe(429)

    vi.setSystemTime(new Date('2026-07-26T12:01:01.000Z'))
    expect(enforceRateLimit(request(), rule)).toBeNull()
  })
})
