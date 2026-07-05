import { NextRequest, NextResponse } from 'next/server'

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
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
}

function resolveAllowedOrigin(origin: string | null): string {
  if (ALLOWED_ORIGINS.includes('*')) return '*'
  if (origin && ALLOWED_ORIGINS.includes(origin)) return origin
  return ALLOWED_ORIGINS[0] ?? '*'
}

export function proxy(request: NextRequest) {
  const allowOrigin = resolveAllowedOrigin(request.headers.get('origin'))
  const headers = { 'Access-Control-Allow-Origin': allowOrigin, ...CORS_HEADERS_BASE }

  if (request.method === 'OPTIONS') {
    return new NextResponse(null, { status: 204, headers })
  }

  const response = NextResponse.next()
  for (const [key, value] of Object.entries(headers)) {
    response.headers.set(key, value)
  }
  return response
}

export const config = {
  matcher: '/api/:path*',
}
