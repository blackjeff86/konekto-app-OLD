import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Avisos da recepção pro quarto do hóspede autenticado — o token do
// hóspede não carrega `stayId` (foi assinado antes da Stay existir como
// conceito), então resolve pelo próprio registro do Guest.
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

  const notices = await prisma.stayNotice.findMany({
    where: { stayId: guest.stayId },
    orderBy: { createdAt: 'desc' },
  })
  return NextResponse.json(notices)
}
