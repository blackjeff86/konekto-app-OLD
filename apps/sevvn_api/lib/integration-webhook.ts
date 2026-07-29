import { createHmac } from 'crypto'
import { prisma } from '@/lib/prisma'
import { isSafeHost, safeParseUrl } from '@/lib/ssrf-guard'

export interface OrderWebhookOrder {
  id: string
  hotelId: string
  guestId: string
  serviceId: string
  serviceItemId: string
  itemName: string
  price: number | null
  quantity: number
  note: string | null
  scheduledFor: Date | null
  createdAt: Date
}

const DISPATCH_TIMEOUT_MS = 5000
const MAX_REDIRECTS = 3

interface DispatchResult {
  ok: boolean
  error: string | null
}

// Igual à defesa de SSRF de `image-proxy` (`lib/ssrf-guard.ts`): resolve o
// host de verdade (não só a string) a cada hop, e segue redirect manualmente
// pra nunca deixar um 3xx escapar pra um IP interno depois da checagem
// inicial passar. `webhookUrl` é uma URL que um `gerente` cola no portal —
// sem essa validação, um hotel malicioso (ou uma conta comprometida)
// conseguiria usar a Sevvn como proxy pra bater em infraestrutura interna
// (ex: endpoint de metadata de nuvem) a cada pedido criado.
async function postSafely(initialUrl: string, body: string, signature: string): Promise<DispatchResult> {
  let currentUrl = initialUrl

  for (let redirectCount = 0; redirectCount <= MAX_REDIRECTS; redirectCount++) {
    const parsed = safeParseUrl(currentUrl)
    if (!parsed) return { ok: false, error: 'invalid_webhook_url' }
    if (!(await isSafeHost(parsed.hostname))) return { ok: false, error: 'unsafe_webhook_url' }

    let response: Response
    try {
      response = await fetch(parsed.toString(), {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-Sevvn-Signature': `sha256=${signature}`,
          'X-Konekto-Signature': `sha256=${signature}`,
        },
        body,
        redirect: 'manual',
        signal: AbortSignal.timeout(DISPATCH_TIMEOUT_MS),
      })
    } catch (error) {
      return { ok: false, error: error instanceof Error ? error.message : 'unknown_error' }
    }

    if ([301, 302, 303, 307, 308].includes(response.status)) {
      const location = response.headers.get('location')
      if (!location) return { ok: false, error: 'redirect_without_location' }
      currentUrl = new URL(location, parsed).toString()
      continue
    }

    return response.ok ? { ok: true, error: null } : { ok: false, error: `HTTP ${response.status}` }
  }

  return { ok: false, error: 'too_many_redirects' }
}

/// Envia o pedido recém-criado pro sistema do hotel (PMS/middleware), se o
/// hotel tiver configurado uma `webhookUrl` em Configurações > Integrações.
/// Assina o corpo com HMAC-SHA256 (`webhookSecret` do hotel) no header
/// `X-Sevvn-Signature` (mantendo `X-Konekto-Signature` por compatibilidade),
/// mesma convenção do GitHub/Stripe, pro lado receptor poder confirmar que
/// a chamada veio mesmo da Sevvn.
///
/// NUNCA lança — uma falha de entrega (timeout, DNS, 500 do outro lado)
/// nunca pode derrubar a criação do pedido em si, só fica registrada em
/// `HotelIntegration.lastOutboundOk/lastOutboundError` pro portal mostrar.
/// Sem fila/retry nesta v1 (sem infra de job assíncrono no projeto ainda).
export async function dispatchOrderWebhook(order: OrderWebhookOrder, hotelId: string): Promise<void> {
  const integration = await prisma.hotelIntegration.findUnique({ where: { hotelId } })
  if (!integration?.webhookUrl) return

  const body = JSON.stringify({ event: 'order.created', order })
  const signature = createHmac('sha256', integration.webhookSecret).update(body).digest('hex')

  const result = await postSafely(integration.webhookUrl, body, signature)
  await prisma.hotelIntegration.update({
    where: { hotelId },
    data: { lastOutboundAt: new Date(), lastOutboundOk: result.ok, lastOutboundError: result.error },
  })
}
