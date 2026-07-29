import crypto from 'node:crypto'
import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

function generateInviteCode(): string {
  return crypto.randomBytes(5).toString('hex').toUpperCase()
}

// Só gerente cria convite, e sempre pro próprio hotelId (nunca um hotelId
// arbitrário vindo do body) — role fica travado em 'recepcao', não é
// aceito como input.
export async function POST(request: NextRequest) {
  let staff
  try {
    staff = await requireStaffRole(request, ['gerente'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const invite = await prisma.staffInvite.create({
    data: { code: generateInviteCode(), hotelId: staff.hotelId, role: 'recepcao' },
  })

  return NextResponse.json({ code: invite.code }, { status: 201 })
}
