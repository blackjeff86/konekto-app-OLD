import { NextRequest, NextResponse } from 'next/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { CORRELATION_ID_HEADER } from '@/lib/request-context'
import { withRequestLogging } from './request-logging'

describe('withRequestLogging', () => {
  const infoSpy = vi.spyOn(console, 'info').mockImplementation(() => {})
  const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('preserves an incoming correlation id and attaches it to the response', async () => {
    const request = new NextRequest('http://localhost/api/test', {
      headers: {
        [CORRELATION_ID_HEADER]: 'corr-123',
        'x-forwarded-for': '203.0.113.10',
      },
    })

    const response = await withRequestLogging(request, { route: '/api/test', surface: 'test-surface' }, async () =>
      NextResponse.json({ ok: true }),
    )

    expect(response.headers.get(CORRELATION_ID_HEADER)).toBe('corr-123')
    expect(infoSpy).toHaveBeenCalledTimes(1)
    expect(JSON.parse(infoSpy.mock.calls[0]?.[0] as string)).toMatchObject({
      correlationId: 'corr-123',
      event: 'api_request_completed',
      path: '/api/test',
      route: '/api/test',
      status: 200,
      surface: 'test-surface',
    })
  })

  it('generates a correlation id when the request does not provide one', async () => {
    const request = new NextRequest('http://localhost/api/test')

    const response = await withRequestLogging(request, { route: '/api/test', surface: 'test-surface' }, async () =>
      NextResponse.json({ ok: true }),
    )

    expect(response.headers.get(CORRELATION_ID_HEADER)).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    )
  })

  it('logs a structured error event before rethrowing', async () => {
    const request = new NextRequest('http://localhost/api/test', {
      headers: { [CORRELATION_ID_HEADER]: 'corr-err' },
    })

    await expect(
      withRequestLogging(request, { route: '/api/test', surface: 'test-surface' }, async () => {
        throw new Error('boom')
      }),
    ).rejects.toThrow('boom')

    expect(errorSpy).toHaveBeenCalledTimes(1)
    expect(JSON.parse(errorSpy.mock.calls[0]?.[0] as string)).toMatchObject({
      correlationId: 'corr-err',
      errorMessage: 'boom',
      errorName: 'Error',
      event: 'api_request_failed',
      route: '/api/test',
      surface: 'test-surface',
    })
  })
})
