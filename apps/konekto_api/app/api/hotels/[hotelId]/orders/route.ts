import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

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

  const orders = await prisma.order.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'desc' },
    include: { guest: { select: { firstName: true, lastName: true, stay: { select: { roomNumber: true } } } } },
  })

  // Achata `guest.stay.roomNumber` pra `guest.roomNumber` — mantém o
  // formato de resposta que o portal já espera, sem precisar tocar no
  // modelo Dart por causa da mudança de onde roomNumber mora no schema.
  const flattened = orders.map((order) => ({
    ...order,
    guest: { firstName: order.guest.firstName, lastName: order.guest.lastName, roomNumber: order.guest.stay.roomNumber },
  }))
  return NextResponse.json(flattened)
}
