import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Total de mensagens da recepção ainda não lidas pelo hóspede — alimenta o
// indicador no sininho da Home, sem precisar abrir o chat inteiro só pra
// saber se tem novidade.
export async function GET(request: NextRequest) {
  let guestPayload
  try {
    guestPayload = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const guest = await prisma.guest.findUnique({ where: { id: guestPayload.sub }, select: { stayId: true } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const count = await prisma.stayMessage.count({
    where: { stayId: guest.stayId, senderType: 'staff', readByGuest: false },
  })
  return NextResponse.json({ count })
}
