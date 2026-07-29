import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'
import { computeStayBill } from '@/lib/stay-billing'

export const runtime = 'nodejs'

// Conta consolidada da estadia do hóspede autenticado — o saldo é
// compartilhado por todo mundo hospedado no mesmo quarto (mesmo padrão do
// chat em /api/guest/messages), não é por hóspede individual.
export async function GET(request: NextRequest) {
  let guestPayload
  try {
    guestPayload = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const guest = await prisma.guest.findUnique({ where: { id: guestPayload.sub }, select: { stayId: true, hotelId: true } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const paymentAccount = await prisma.hotelPaymentAccount.findUnique({ where: { hotelId: guest.hotelId } })
  const bill = await computeStayBill(guest.stayId)

  return NextResponse.json({
    ...bill,
    onlinePaymentAvailable: paymentAccount?.status === 'verified',
  })
}
