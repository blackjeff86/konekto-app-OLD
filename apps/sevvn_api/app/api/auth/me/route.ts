import { NextRequest, NextResponse } from 'next/server'
import { verifyStaffToken } from '@/lib/jwt'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

// Sempre resolve de novo contra o Postgres em vez de confiar só no claim do
// token — preserva a semântica do antigo resolveStaffSession (Firestore):
// uma conta com staff removido depois do login continua barrada, mesmo com
// um token ainda válido.
export async function GET(request: NextRequest) {
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) {
    return NextResponse.json({ error: 'missing_token' }, { status: 401 })
  }

  let payload
  try {
    payload = await verifyStaffToken(token)
  } catch {
    return NextResponse.json({ error: 'invalid_token' }, { status: 401 })
  }

  const staff = await prisma.staff.findUnique({ where: { id: payload.sub } })
  if (!staff) {
    return NextResponse.json({ error: 'staff_not_found' }, { status: 401 })
  }

  return NextResponse.json({
    staff: { id: staff.id, hotelId: staff.hotelId, role: staff.role, name: staff.name, email: staff.email },
  })
}
