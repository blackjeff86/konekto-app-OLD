import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'
import { computeStayBill } from '@/lib/stay-billing'
import { createOrderWithSplit, PagarmeError } from '@/lib/pagarme'

export const runtime = 'nodejs'

const paySchema = z.object({ cardToken: z.string().trim().min(1) })

function platformFeePercent(): number {
  const raw = process.env.PAGARME_PLATFORM_FEE_PERCENT
  const parsed = raw ? Number(raw) : NaN
  return Number.isFinite(parsed) && parsed >= 0 && parsed <= 100 ? parsed : 5
}

type PayResult =
  | { kind: 'guard'; error: string; status: number }
  | { kind: 'failed' }
  | { kind: 'ok'; id: string; status: string; amount: number }

// Paga o saldo em aberto da conta da estadia com cartão de crédito
// (`cardToken` já tokenizado client-side pelo script do Pagar.me — nunca
// recebemos dado bruto de cartão aqui). O valor cobrado é sempre
// recalculado no servidor (nunca confiar num total mandado pelo cliente).
//
// Tudo roda dentro de uma única transação com um advisory lock em
// `stayId` (`pg_advisory_xact_lock`) — sem isso, duas chamadas
// concorrentes desse endpoint (dois cliques, duas abas, um retry)
// poderiam ambas calcular o mesmo saldo e cobrar o hóspede duas vezes
// antes que a primeira terminasse. O lock é liberado automaticamente no
// fim da transação (commit ou rollback).
export async function POST(request: NextRequest) {
  let guestPayload
  try {
    guestPayload = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = paySchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const guest = await prisma.guest.findUnique({
    where: { id: guestPayload.sub },
    select: { stayId: true, hotelId: true, firstName: true, lastName: true, documentNumber: true },
  })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const masterRecipientId = process.env.PAGARME_MASTER_RECIPIENT_ID
  if (!masterRecipientId) {
    return NextResponse.json({ error: 'payments_not_configured' }, { status: 503 })
  }

  const result = await prisma.$transaction<PayResult>(
    async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${guest.stayId}))`

      const paymentAccount = await tx.hotelPaymentAccount.findUnique({ where: { hotelId: guest.hotelId } })
      if (!paymentAccount || paymentAccount.status !== 'verified') {
        return { kind: 'guard', error: 'hotel_not_configured_for_payments', status: 400 }
      }

      const bill = await computeStayBill(guest.stayId, tx)
      if (bill.balanceDue <= 0) {
        return { kind: 'guard', error: 'nothing_to_pay', status: 400 }
      }

      const feePercent = platformFeePercent()
      const platformFeeAmount = Math.round(bill.balanceDue * feePercent) / 100
      const hotelAmount = Math.round((bill.balanceDue - platformFeeAmount) * 100) / 100

      const stayPayment = await tx.stayPayment.create({
        data: {
          hotelId: guest.hotelId,
          stayId: guest.stayId,
          guestId: guestPayload.sub,
          amount: bill.balanceDue,
          platformFeeAmount,
          hotelAmount,
          status: 'pending',
        },
      })

      try {
        const charge = await createOrderWithSplit({
          code: stayPayment.id,
          amountInCents: Math.round(bill.balanceDue * 100),
          cardToken: parsed.data.cardToken,
          customerName: `${guest.firstName} ${guest.lastName}`,
          customerDocument: guest.documentNumber,
          split: [
            {
              recipientId: masterRecipientId,
              percentage: feePercent,
              liable: true,
              chargeProcessingFee: true,
              chargeRemainderFee: false,
            },
            {
              recipientId: paymentAccount.pagarmeRecipientId,
              percentage: 100 - feePercent,
              liable: false,
              chargeProcessingFee: false,
              chargeRemainderFee: true,
            },
          ],
        })

        // Cartão de crédito costuma resolver síncrono ("paid"/"failed"),
        // mas pode ficar em análise antifraude — nesse caso o webhook
        // (`/api/webhooks/pagarme`) atualiza o status depois.
        const isPaid = charge.chargeStatus === 'paid' || charge.orderStatus === 'paid'
        const updated = await tx.stayPayment.update({
          where: { id: stayPayment.id },
          data: {
            status: isPaid ? 'paid' : 'pending',
            pagarmeOrderId: charge.orderId,
            pagarmeChargeId: charge.chargeId,
          },
        })
        return { kind: 'ok', id: updated.id, status: updated.status, amount: updated.amount }
      } catch (error) {
        // O detalhe bruto do Pagar.me (pode conter diagnóstico interno
        // deles) fica só em `failureReason`, pra investigação — nunca
        // devolvido ao hóspede na resposta da API.
        const detail = error instanceof PagarmeError ? JSON.stringify(error.body) : error instanceof Error ? error.message : 'unknown_error'
        await tx.stayPayment.update({
          where: { id: stayPayment.id },
          data: { status: 'failed', failureReason: detail.slice(0, 500) },
        })
        return { kind: 'failed' }
      }
    },
    { maxWait: 5000, timeout: 20000 },
  )

  if (result.kind === 'guard') {
    return NextResponse.json({ error: result.error }, { status: result.status })
  }
  if (result.kind === 'failed') {
    return NextResponse.json({ error: 'payment_failed' }, { status: 402 })
  }
  return NextResponse.json({ id: result.id, status: result.status, amount: result.amount })
}
