import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Marca todos os pedidos do hóspede como vistos — chamado ao abrir "Meus
// Pedidos", mesmo gatilho que `POST /api/guest/messages/read` já usa pro
// chat.
export async function POST(request: NextRequest) {
  let guest
  try {
    guest = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  await prisma.order.updateMany({
    where: { guestId: guest.sub, statusSeenByGuest: false },
    data: { statusSeenByGuest: true },
  })
  return NextResponse.json({ ok: true })
}
