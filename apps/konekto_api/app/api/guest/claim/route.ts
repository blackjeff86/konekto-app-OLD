import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { signGuestToken } from '@/lib/guest-auth'

export const runtime = 'nodejs'

const claimSchema = z.object({ code: z.string().min(1) })

interface HotelWifi {
  network_name?: string
  password?: string
}

export async function POST(request: NextRequest) {
  const parsed = claimSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const guest = await prisma.guest.findUnique({
    where: { accessCode: parsed.data.code.trim().toUpperCase() },
    include: { stay: true },
  })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }
  if (guest.status === 'revoked' || guest.stay.status === 'closed') {
    return NextResponse.json({ error: 'access_revoked' }, { status: 403 })
  }

  const token = await signGuestToken({
    sub: guest.id,
    hotelId: guest.hotelId,
    firstName: guest.firstName,
    lastName: guest.lastName,
    roomNumber: guest.stay.roomNumber,
  })

  // Nome da rede de wifi é sempre do hotel; a senha pode ser sobrescrita
  // por hóspede (guest.wifiPassword), com fallback pra senha padrão do
  // hotel quando não for definida.
  const hotelGuestInfo = await prisma.hotelContent.findUnique({
    where: { hotelId_docName: { hotelId: guest.hotelId, docName: 'guestInfo' } },
  })
  const hotelWifi = (hotelGuestInfo?.data as { wifi?: HotelWifi } | null)?.wifi
  const wifiNetworkName = hotelWifi?.network_name ?? null
  const wifiPassword = guest.wifiPassword ?? hotelWifi?.password ?? null

  return NextResponse.json({
    token,
    guest: {
      firstName: guest.firstName,
      lastName: guest.lastName,
      roomNumber: guest.stay.roomNumber,
      hotelId: guest.hotelId,
      checkInDate: guest.stay.checkInDate,
      checkOutDate: guest.stay.checkOutDate,
      wifiNetworkName,
      wifiPassword,
    },
  })
}
