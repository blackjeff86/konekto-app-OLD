import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Total de pedidos do próprio hóspede com mudança de status ainda não vista
// — alimenta o número no sininho da Home, somado ao de mensagens não lidas
// (`/api/guest/messages/unread-count`).
export async function GET(request: NextRequest) {
  let guest
  try {
    guest = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const count = await prisma.order.count({ where: { guestId: guest.sub, statusSeenByGuest: false } })
  return NextResponse.json({ count })
}
