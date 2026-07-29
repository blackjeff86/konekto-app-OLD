import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Marca como lidas (pelo hotel) as mensagens que a Sevvn mandou — chamado
// quando o staff abre a tela "Suporte" no portal.
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
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

  await prisma.platformSupportMessage.updateMany({
    where: { hotelId, senderType: 'platform', readByHotel: false },
    data: { readByHotel: true },
  })
  return NextResponse.json({ success: true })
}
