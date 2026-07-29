import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { generateApiKey, generateWebhookSecret } from '@/lib/integration-keys'
import { isSafeHost, safeParseUrl } from '@/lib/ssrf-guard'

export const runtime = 'nodejs'

async function authorizeGerente(request: NextRequest, hotelId: string): Promise<NextResponse | null> {
  try {
    const staff = await requireStaffRole(request, ['gerente'])
    if (staff.hotelId !== hotelId) {
      return NextResponse.json({ error: 'forbidden' }, { status: 403 })
    }
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  return null
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const integration = await prisma.hotelIntegration.findUnique({ where: { hotelId } })
  if (!integration) {
    return NextResponse.json({ configured: false })
  }
  return NextResponse.json({
    configured: true,
    apiKeyPrefix: integration.apiKeyPrefix,
    webhookUrl: integration.webhookUrl,
    enabled: integration.enabled,
    lastInboundSyncAt: integration.lastInboundSyncAt,
    lastOutboundAt: integration.lastOutboundAt,
    lastOutboundOk: integration.lastOutboundOk,
  })
}

const postSchema = z.object({
  action: z.literal('rotate_key'),
})

// Gera (ou renova) a chave de API que o PMS/middleware do hotel usa pra
// autenticar nas rotas de recebimento (`/api/integrations/v1/...`). A
// chave em texto puro só existe nesta resposta — só o hash fica gravado.
// Renovar a chave não mexe no webhook (URL/segredo), só invalida a chave
// antiga.
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const parsed = postSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const { plainKey, hash, prefix } = generateApiKey()

  const integration = await prisma.hotelIntegration.upsert({
    where: { hotelId },
    create: {
      hotelId,
      apiKeyHash: hash,
      apiKeyPrefix: prefix,
      webhookSecret: generateWebhookSecret(),
    },
    update: {
      apiKeyHash: hash,
      apiKeyPrefix: prefix,
    },
  })

  return NextResponse.json({
    apiKey: plainKey,
    apiKeyPrefix: integration.apiKeyPrefix,
  })
}

const patchSchema = z.object({
  webhookUrl: z.string().trim().url().nullable(),
})

export async function PATCH(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const parsed = patchSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  // Bloqueia de cara uma URL óbvia demais pra ser válida como webhook
  // (aponta pra IP privado/loopback/metadata de nuvem) — defesa em
  // profundidade além da checagem repetida a cada disparo em
  // `dispatchOrderWebhook` (que também revalida, já que resolução de DNS
  // pode mudar depois de salva).
  if (parsed.data.webhookUrl) {
    const parsedUrl = safeParseUrl(parsed.data.webhookUrl)
    if (!parsedUrl || !(await isSafeHost(parsedUrl.hostname))) {
      return NextResponse.json({ error: 'unsafe_webhook_url' }, { status: 400 })
    }
  }

  const existing = await prisma.hotelIntegration.findUnique({ where: { hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'integration_not_configured' }, { status: 404 })
  }

  const integration = await prisma.hotelIntegration.update({
    where: { hotelId },
    data: { webhookUrl: parsed.data.webhookUrl },
  })

  return NextResponse.json({ configured: true, webhookUrl: integration.webhookUrl })
}
