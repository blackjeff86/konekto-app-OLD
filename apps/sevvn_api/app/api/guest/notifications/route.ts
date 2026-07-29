import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'
import { listGuestNotifications } from '@/lib/basic-notifications'

export const runtime = 'nodejs'

export async function GET(request: NextRequest) {
  let guestPayload
  try {
    guestPayload = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const guest = await prisma.guest.findUnique({ where: { id: guestPayload.sub }, select: { id: true } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const notifications = await listGuestNotifications(prisma, guest.id)
  return NextResponse.json(notifications)
}
