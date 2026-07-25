import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Total de mensagens de hóspede ainda não lidas pelo staff, somando todas
// as estadias do hotel — alimenta o badge de "Quartos" no portal (mesmo
// padrão do badge de pedidos pendentes).
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

  const count = await prisma.stayMessage.count({
    where: { senderType: 'guest', readByStaff: false, stay: { hotelId } },
  })
  return NextResponse.json({ count })
}
