import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Marca como lidas (pelo hóspede) todas as mensagens que a recepção mandou
// nessa estadia — chamado quando o hóspede abre a tela de chat/avisos.
export async function POST(request: NextRequest) {
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

  await prisma.stayMessage.updateMany({
    where: { stayId: guest.stayId, senderType: 'staff', readByGuest: false },
    data: { readByGuest: true },
  })
  return NextResponse.json({ success: true })
}
