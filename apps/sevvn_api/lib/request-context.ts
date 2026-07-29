import { NextRequest, NextResponse } from 'next/server'

export const CORRELATION_ID_HEADER = 'x-correlation-id'

export interface RequestContext {
  clientIp: string | null
  correlationId: string
  method: string
  pathname: string
}

export function getClientIp(request: NextRequest): string | null {
  const forwardedFor = request.headers.get('x-forwarded-for')
  if (forwardedFor) {
    const firstIp = forwardedFor
      .split(',')
      .map((value) => value.trim())
      .find(Boolean)
    if (firstIp) return firstIp
  }

  return request.headers.get('x-real-ip')
}

export function getOrCreateCorrelationId(request: NextRequest): string {
  const existing = request.headers.get(CORRELATION_ID_HEADER)?.trim()
  if (existing) return existing
  return crypto.randomUUID()
}

export function buildRequestContext(request: NextRequest): RequestContext {
  return {
    clientIp: getClientIp(request),
    correlationId: getOrCreateCorrelationId(request),
    method: request.method,
    pathname: request.nextUrl.pathname,
  }
}

export function ensureResponseHasCorrelationId(response: Response, correlationId: string): NextResponse {
  const nextResponse =
    response instanceof NextResponse ? response : new NextResponse(response.body, { headers: response.headers, status: response.status })

  nextResponse.headers.set(CORRELATION_ID_HEADER, correlationId)
  return nextResponse
}
