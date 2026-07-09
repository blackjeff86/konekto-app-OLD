import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { signGuestToken } from '@/lib/guest-auth'

export const runtime = 'nodejs'

const claimSchema = z.object({ code: z.string().min(1) })

export async function POST(request: NextRequest) {
  const parsed = claimSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const guest = await prisma.guest.findUnique({ where: { accessCode: parsed.data.code.trim().toUpperCase() } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }
  if (guest.status === 'revoked') {
    return NextResponse.json({ error: 'access_revoked' }, { status: 403 })
  }

  const token = await signGuestToken({
    sub: guest.id,
    hotelId: guest.hotelId,
    name: guest.name,
    roomNumber: guest.roomNumber,
  })

  return NextResponse.json({
    token,
    guest: { name: guest.name, roomNumber: guest.roomNumber, hotelId: guest.hotelId },
  })
}
