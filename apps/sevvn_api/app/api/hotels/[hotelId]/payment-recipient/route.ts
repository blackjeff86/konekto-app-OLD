import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { getRecipient, PagarmeError } from '@/lib/pagarme'

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

// Não temos um mapeamento oficial e completo de todos os valores possíveis
// de `status` que o Pagar.me pode devolver pro recebedor — só tratamos os
// mais comuns explicitamente; qualquer outro cai em `pending` (mais seguro
// que assumir `verified` por engano num status desconhecido).
function toAccountStatus(pagarmeStatus: string): 'pending' | 'verified' | 'rejected' {
  if (pagarmeStatus === 'active') return 'verified'
  if (pagarmeStatus === 'refused' || pagarmeStatus === 'blocked') return 'rejected'
  return 'pending'
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const account = await prisma.hotelPaymentAccount.findUnique({ where: { hotelId } })
  if (!account) {
    return NextResponse.json({ configured: false })
  }
  return NextResponse.json({
    configured: true,
    recipientId: account.pagarmeRecipientId,
    status: account.status,
    pagarmeStatus: account.pagarmeStatus,
  })
}

const setRecipientSchema = z.object({
  recipientId: z.string().trim().min(1),
})

// O hotel cadastra o recebedor direto no onboarding do próprio Pagar.me
// (KYC completo, já compliant com a regulação do Bacen) e só cola o
// `recipientId` resultante aqui — a gente valida que existe de verdade
// (chamando o Pagar.me) antes de gravar, mas nunca reconstrói o formulário
// de compliance deles.
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const parsed = setRecipientSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  let recipient
  try {
    recipient = await getRecipient(parsed.data.recipientId)
  } catch (error) {
    if (error instanceof PagarmeError) {
      return NextResponse.json({ error: 'recipient_not_found' }, { status: 400 })
    }
    throw error
  }

  const account = await prisma.hotelPaymentAccount.upsert({
    where: { hotelId },
    create: {
      hotelId,
      pagarmeRecipientId: recipient.id,
      status: toAccountStatus(recipient.status),
      pagarmeStatus: recipient.status,
    },
    update: {
      pagarmeRecipientId: recipient.id,
      status: toAccountStatus(recipient.status),
      pagarmeStatus: recipient.status,
    },
  })

  return NextResponse.json({
    configured: true,
    recipientId: account.pagarmeRecipientId,
    status: account.status,
    pagarmeStatus: account.pagarmeStatus,
  })
}
