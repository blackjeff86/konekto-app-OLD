import { timingSafeEqual } from 'crypto'
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

function safeEqual(a: string, b: string): boolean {
  const bufferA = Buffer.from(a)
  const bufferB = Buffer.from(b)
  // Tamanhos diferentes já vazam informação por tempo de execução se
  // comparados direto — normaliza o tamanho antes de comparar, sempre
  // retornando `false` no fim pra esse caso.
  if (bufferA.length !== bufferB.length) {
    timingSafeEqual(bufferA, bufferA)
    return false
  }
  return timingSafeEqual(bufferA, bufferB)
}

// Autenticação via Basic Auth embutido na URL configurada no dashboard do
// Pagar.me (https://<segredo>@seu-dominio/api/webhooks/pagarme) — confirmar
// esse mecanismo direto no dashboard deles ao configurar o webhook em
// produção (não veio 100% documentado na consulta feita durante o
// planejamento desta feature). Comparação em tempo constante — `===`
// simples vazaria um sinal de tempo proporcional a quantos caracteres
// iniciais coincidem com o segredo.
function isAuthorized(request: NextRequest): boolean {
  const secret = process.env.PAGARME_WEBHOOK_SECRET
  if (!secret) return false

  const authHeader = request.headers.get('authorization')
  if (!authHeader?.startsWith('Basic ')) return false

  const decoded = Buffer.from(authHeader.slice('Basic '.length), 'base64').toString('utf-8')
  return safeEqual(decoded, secret) || safeEqual(decoded, `${secret}:`)
}

const webhookPayloadSchema = z.object({
  type: z.string(),
  data: z.object({ id: z.string() }),
})

export async function POST(request: NextRequest) {
  if (!isAuthorized(request)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  const parsed = webhookPayloadSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload' }, { status: 400 })
  }

  const { type: eventType, data } = parsed.data

  if (eventType === 'charge.paid') {
    await prisma.stayPayment.updateMany({ where: { pagarmeChargeId: data.id }, data: { status: 'paid' } })
  } else if (eventType === 'charge.payment_failed') {
    await prisma.stayPayment.updateMany({
      where: { pagarmeChargeId: data.id },
      data: { status: 'failed', failureReason: 'charge.payment_failed' },
    })
  }

  return NextResponse.json({ received: true })
}
