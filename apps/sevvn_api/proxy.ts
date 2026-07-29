import { NextRequest, NextResponse } from 'next/server'
import { CORRELATION_ID_HEADER, getOrCreateCorrelationId } from '@/lib/request-context'

// Next.js 16 renomeou "middleware" pra "proxy" (mesmo arquivo/conceito,
// nome do arquivo e da função exportada mudaram).
//
// Nota: `ALLOWED_ORIGINS=` (valor vazio, não ausente) no .env resulta em
// string vazia, não undefined — por isso o fallback pro wildcard checa
// vazio explicitamente em vez de usar só `?? '*'`.
const rawAllowedOrigins = process.env.ALLOWED_ORIGINS?.trim()
const ALLOWED_ORIGINS = rawAllowedOrigins ? rawAllowedOrigins.split(',').map((origin) => origin.trim()) : ['*']

const CORS_HEADERS_BASE = {
  'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': `Content-Type, Authorization, ${CORRELATION_ID_HEADER}`,
  'Access-Control-Expose-Headers': CORRELATION_ID_HEADER,
  'Access-Control-Max-Age': '86400',
}

function resolveAllowedOrigin(origin: string | null): string {
  if (ALLOWED_ORIGINS.includes('*')) return '*'
  if (origin && ALLOWED_ORIGINS.includes(origin)) return origin
  return ALLOWED_ORIGINS[0] ?? '*'
}

export function proxy(request: NextRequest) {
  const correlationId = getOrCreateCorrelationId(request)
  const allowOrigin = resolveAllowedOrigin(request.headers.get('origin'))
  const headers = {
    'Access-Control-Allow-Origin': allowOrigin,
    [CORRELATION_ID_HEADER]: correlationId,
    ...CORS_HEADERS_BASE,
  }

  if (request.method === 'OPTIONS') {
    return new NextResponse(null, { status: 204, headers })
  }

  const requestHeaders = new Headers(request.headers)
  requestHeaders.set(CORRELATION_ID_HEADER, correlationId)

  const response = NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  })
  for (const [key, value] of Object.entries(headers)) {
    response.headers.set(key, value)
  }
  return response
}

export const config = {
  matcher: '/api/:path*',
}
