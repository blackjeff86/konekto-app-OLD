import { NextRequest, NextResponse } from 'next/server'

interface RateLimitState {
  count: number
  resetAt: number
}

interface RateLimitRule {
  bucket: string
  max: number
  windowMs: number
}

type GlobalRateLimitStore = typeof globalThis & {
  __sevvnRateLimitStore?: Map<string, RateLimitState>
}

function getStore(): Map<string, RateLimitState> {
  const globalStore = globalThis as GlobalRateLimitStore
  if (!globalStore.__sevvnRateLimitStore) {
    globalStore.__sevvnRateLimitStore = new Map()
  }
  return globalStore.__sevvnRateLimitStore
}

function getClientIp(request: NextRequest): string {
  const forwardedFor = request.headers.get('x-forwarded-for')
  if (forwardedFor) {
    const first = forwardedFor.split(',')[0]?.trim()
    if (first) return first
  }

  const realIp = request.headers.get('x-real-ip')?.trim()
  if (realIp) return realIp

  return 'unknown'
}

function buildKey(request: NextRequest, rule: RateLimitRule): string {
  return `${rule.bucket}:${getClientIp(request)}`
}

function rateLimitedResponse(state: RateLimitState, rule: RateLimitRule): NextResponse {
  const retryAfterSeconds = Math.max(1, Math.ceil((state.resetAt - Date.now()) / 1000))

  return NextResponse.json(
    {
      error: 'rate_limited',
      retryAfterSeconds,
      limit: rule.max,
      windowMs: rule.windowMs,
    },
    {
      status: 429,
      headers: {
        'Retry-After': String(retryAfterSeconds),
      },
    },
  )
}

export function enforceRateLimit(request: NextRequest, rule: RateLimitRule): NextResponse | null {
  const store = getStore()
  const now = Date.now()
  const key = buildKey(request, rule)
  const current = store.get(key)

  if (!current || now >= current.resetAt) {
    store.set(key, { count: 1, resetAt: now + rule.windowMs })
    return null
  }

  if (current.count >= rule.max) {
    return rateLimitedResponse(current, rule)
  }

  current.count += 1
  store.set(key, current)
  return null
}

export function __resetRateLimitStore() {
  getStore().clear()
}
