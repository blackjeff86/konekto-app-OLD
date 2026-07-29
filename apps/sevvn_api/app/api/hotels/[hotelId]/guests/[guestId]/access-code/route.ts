import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { flattenStayRoomNumber } from '@/lib/stay-shape'
import { generateAccessCode } from '@/lib/guest-access-code'

export const runtime = 'nodejs'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; guestId: string }> },
) {
  const { hotelId, guestId } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente', 'recepcao'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const existing = await prisma.guest.findFirst({
    where: { id: guestId, hotelId },
    include: {
      stay: {
        select: { id: true, room: { select: { number: true } }, checkInDate: true, checkOutDate: true, status: true },
      },
      orders: { orderBy: { createdAt: 'desc' } },
    },
  })
  if (!existing) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const guest = await prisma.guest.update({
    where: { id: guestId },
    data: { accessCode: generateAccessCode(hotelId) },
    include: {
      stay: {
        select: { id: true, room: { select: { number: true } }, checkInDate: true, checkOutDate: true, status: true },
      },
      orders: { orderBy: { createdAt: 'desc' } },
    },
  })

  return NextResponse.json({ ...guest, stay: flattenStayRoomNumber(guest.stay) })
}
