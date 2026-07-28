import { NextRequest, NextResponse } from 'next/server'
import { isSafeHost, safeParseUrl } from '@/lib/ssrf-guard'
import { enforceRateLimit } from '@/lib/rate-limit'
import { withRequestLogging } from '@/lib/request-logging'

export const runtime = 'nodejs'

// Imagens de item/carrossel são URLs que o hotel cola no portal, apontando
// pra qualquer host externo — o app do hóspede roda com CanvasKit no
// Flutter Web, que precisa baixar os bytes da imagem via fetch() do
// navegador pra decodificar numa textura (diferente de uma <img> comum).
// Isso exige CORS do host de origem, que a grande maioria não configura
// (ex: fotos coladas de um site qualquer). Esse proxy busca a imagem no
// servidor (sem restrição de CORS) e devolve com `Access-Control-Allow-Origin: *`,
// funcionando com qualquer host de origem, sem depender da configuração dele.
const MAX_BYTES = 8 * 1024 * 1024
const FETCH_TIMEOUT_MS = 8000
const MAX_REDIRECTS = 3
const ALLOWED_CONTENT_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/avif',
  'image/svg+xml',
])

type ProxyResult =
  | { ok: true; body: Uint8Array; contentType: string }
  | { ok: false; status: number }

async function fetchImageSafely(initialUrl: string): Promise<ProxyResult> {
  let currentUrl = initialUrl

  for (let redirectCount = 0; redirectCount <= MAX_REDIRECTS; redirectCount++) {
    const parsed = safeParseUrl(currentUrl)
    if (!parsed) return { ok: false, status: 400 }
    if (!(await isSafeHost(parsed.hostname))) return { ok: false, status: 400 }

    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS)
    let response: Response
    try {
      response = await fetch(parsed.toString(), { signal: controller.signal, redirect: 'manual' })
    } catch {
      clearTimeout(timeout)
      return { ok: false, status: 502 }
    }
    clearTimeout(timeout)

    if ([301, 302, 303, 307, 308].includes(response.status)) {
      const location = response.headers.get('location')
      if (!location) return { ok: false, status: 502 }
      currentUrl = new URL(location, parsed).toString()
      continue
    }

    if (!response.ok || !response.body) return { ok: false, status: 502 }

    const contentType = response.headers.get('content-type')?.split(';')[0]?.trim().toLowerCase() ?? ''
    if (!ALLOWED_CONTENT_TYPES.has(contentType)) return { ok: false, status: 415 }

    const contentLengthHeader = response.headers.get('content-length')
    if (contentLengthHeader && Number(contentLengthHeader) > MAX_BYTES) return { ok: false, status: 413 }

    const reader = response.body.getReader()
    const chunks: Uint8Array[] = []
    let total = 0
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      total += value.byteLength
      if (total > MAX_BYTES) {
        await reader.cancel()
        return { ok: false, status: 413 }
      }
      chunks.push(value)
    }

    const merged = new Uint8Array(total)
    let offset = 0
    for (const chunk of chunks) {
      merged.set(chunk, offset)
      offset += chunk.byteLength
    }
    return { ok: true, body: merged, contentType }
  }

  return { ok: false, status: 502 }
}

export async function GET(request: NextRequest) {
  return withRequestLogging(request, { route: '/api/image-proxy', surface: 'public-asset-proxy' }, async () => {
    const rateLimited = enforceRateLimit(request, {
      bucket: 'image-proxy',
      max: 60,
      windowMs: 60 * 1000,
    })
    if (rateLimited) return rateLimited

    const url = request.nextUrl.searchParams.get('url')
    if (!url) {
      return NextResponse.json({ error: 'missing_url' }, { status: 400 })
    }

    const result = await fetchImageSafely(url)
    if (!result.ok) {
      return NextResponse.json({ error: 'image_fetch_failed' }, { status: result.status })
    }

    return new NextResponse(Buffer.from(result.body), {
      status: 200,
      headers: {
        'Content-Type': result.contentType,
        'Cache-Control': 'public, max-age=86400, s-maxage=604800, stale-while-revalidate=86400',
        'Access-Control-Allow-Origin': '*',
      },
    })
  })
}
