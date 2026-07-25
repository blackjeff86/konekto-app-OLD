import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Revoga o acesso de um membro da equipe (remove o registro — `Staff` não
// tem relação de volta com nenhuma outra tabela, então apagar é seguro,
// sem deixar referência solta). Bloqueia remover o último `gerente` do
// hotel: sem isso, o hotel ficaria sem ninguém com permissão pra
// gerenciar Configurações/Equipe, exigindo suporte manual pra recuperar.
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; staffId: string }> },
) {
  const { hotelId, staffId } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const target = await prisma.staff.findUnique({ where: { id: staffId } })
  if (!target || target.hotelId !== hotelId) {
    return NextResponse.json({ error: 'staff_not_found' }, { status: 404 })
  }

  if (target.role === 'gerente') {
    const managerCount = await prisma.staff.count({ where: { hotelId, role: 'gerente' } })
    if (managerCount <= 1) {
      return NextResponse.json({ error: 'cannot_remove_last_manager' }, { status: 400 })
    }
  }

  await prisma.staff.delete({ where: { id: staffId } })
  return NextResponse.json({ success: true })
}
