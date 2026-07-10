import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Detalhe completo do hóspede — cadastro + estadia (quarto/datas) + todos
// os pedidos que ele já fez (serviço de quarto e reservas), pra tela de
// detalhe do portal (substitui o modal antigo).
export async function GET(
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

  const guest = await prisma.guest.findFirst({
    where: { id: guestId, hotelId },
    include: {
      stay: { select: { id: true, roomNumber: true, checkInDate: true, checkOutDate: true, status: true } },
      orders: { orderBy: { createdAt: 'desc' } },
    },
  })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }
  return NextResponse.json(guest)
}

// Revoga em vez de apagar — preserva o registro pra quando Pedidos
// existir (um pedido vai referenciar um Guest).
export async function DELETE(
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

  const existing = await prisma.guest.findUnique({ where: { id: guestId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const updated = await prisma.guest.update({ where: { id: guestId }, data: { status: 'revoked' } })
  return NextResponse.json(updated)
}
