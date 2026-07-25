import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Marca como lidas (pelo staff) todas as mensagens que o(s) hóspede(s)
// dessa estadia mandaram — chamado quando a recepção abre o chat da
// estadia no portal.
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; stayId: string }> },
) {
  const { hotelId, stayId } = await params

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

  const stay = await prisma.stay.findFirst({ where: { id: stayId, hotelId } })
  if (!stay) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }

  await prisma.stayMessage.updateMany({
    where: { stayId, senderType: 'guest', readByStaff: false },
    data: { readByStaff: true },
  })
  return NextResponse.json({ success: true })
}
