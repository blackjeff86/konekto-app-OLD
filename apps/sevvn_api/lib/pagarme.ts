const PAGARME_API_BASE = 'https://api.pagar.me/core/v5'

function getApiKey(): string {
  const apiKey = process.env.PAGARME_API_KEY
  if (!apiKey) {
    throw new Error('Missing required env var: PAGARME_API_KEY')
  }
  return apiKey
}

// Autenticação v5 é HTTP Basic com a secret key como usuário e senha em
// branco (confirmado na doc oficial: "User: SecretKey Password: vazio").
function authHeader(): string {
  return `Basic ${Buffer.from(`${getApiKey()}:`).toString('base64')}`
}

export class PagarmeError extends Error {
  readonly status: number
  readonly body: unknown

  constructor(status: number, body: unknown) {
    super(`Pagar.me request failed with status ${status}`)
    this.status = status
    this.body = body
  }
}

async function pagarmeRequest<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${PAGARME_API_BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: authHeader(),
      ...init?.headers,
    },
  })
  const body = await response.json().catch(() => null)
  if (!response.ok) {
    throw new PagarmeError(response.status, body)
  }
  return body as T
}

export interface PagarmeRecipient {
  id: string
  status: string
}

/// Confirma que um `recipientId` colado pelo hotel no portal existe e
/// devolve o status atual — a equipe do hotel faz o cadastro completo de
/// KYC direto pelo onboarding do próprio Pagar.me, nós só validamos e
/// espelhamos o status, nunca reconstruímos o formulário de compliance.
export async function getRecipient(recipientId: string): Promise<PagarmeRecipient> {
  return pagarmeRequest<PagarmeRecipient>(`/recipients/${recipientId}`)
}

export interface SplitRecipient {
  recipientId: string
  /// Percentual (0-100) que esse recebedor recebe do valor total.
  percentage: number
  liable: boolean
  chargeProcessingFee: boolean
  chargeRemainderFee: boolean
}

export interface CreateOrderWithSplitInput {
  /// Identificador único da cobrança (idempotência do lado Pagar.me) —
  /// usar o id do `StayPayment` já criado no nosso banco.
  code: string
  amountInCents: number
  cardToken: string
  customerName: string
  customerDocument: string
  customerEmail?: string
  split: SplitRecipient[]
}

export interface PagarmeOrderResult {
  orderId: string
  orderStatus: string
  chargeId?: string
  chargeStatus?: string
}

interface PagarmeOrderResponse {
  id: string
  status: string
  charges?: Array<{ id: string; status: string }>
}

/// Cria um pedido no Pagar.me com pagamento em cartão de crédito
/// (`cardToken` já tokenizado client-side, nunca dado bruto de cartão) e
/// split entre os recebedores informados. `split` é um campo top-level do
/// pedido (não aninhado dentro de `payments`), confirmado na documentação
/// oficial da API v5.
export async function createOrderWithSplit(input: CreateOrderWithSplitInput): Promise<PagarmeOrderResult> {
  const order = await pagarmeRequest<PagarmeOrderResponse>('/orders', {
    method: 'POST',
    body: JSON.stringify({
      code: input.code,
      items: [{ amount: input.amountInCents, description: 'Conta da estadia', quantity: 1 }],
      customer: {
        name: input.customerName,
        document: input.customerDocument,
        type: 'individual',
        email: input.customerEmail,
      },
      payments: [
        {
          payment_method: 'credit_card',
          credit_card: { card_token: input.cardToken },
        },
      ],
      split: input.split.map((recipient) => ({
        recipient_id: recipient.recipientId,
        type: 'percentage',
        amount: recipient.percentage,
        options: {
          liable: recipient.liable,
          charge_processing_fee: recipient.chargeProcessingFee,
          charge_remainder_fee: recipient.chargeRemainderFee,
        },
      })),
    }),
  })

  const charge = order.charges?.[0]
  return { orderId: order.id, orderStatus: order.status, chargeId: charge?.id, chargeStatus: charge?.status }
}
