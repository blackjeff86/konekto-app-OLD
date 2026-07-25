import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Lista a equipe do próprio hotel (gerente-only) — nunca devolve
// `passwordHash`, só o necessário pra exibir/gerenciar quem tem acesso.
export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

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

  const members = await prisma.staff.findMany({
    where: { hotelId },
    select: { id: true, name: true, email: true, role: true, createdAt: true },
    orderBy: { createdAt: 'asc' },
  })
  return NextResponse.json(members)
}
