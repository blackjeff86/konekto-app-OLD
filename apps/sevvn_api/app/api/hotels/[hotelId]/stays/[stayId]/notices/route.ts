import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const createNoticeSchema = z.object({ message: z.string().trim().min(1).max(500) })

// Aviso da recepção pra TODOS os hóspedes de uma estadia de uma vez (ex:
// "seu jantar está pronto", "checkout às 12h") — só leitura, sem resposta;
// cada hóspede lê via `GET /api/guest/notices` no próprio app.
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

  const parsed = createNoticeSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const stay = await prisma.stay.findFirst({ where: { id: stayId, hotelId } })
  if (!stay) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }

  const notice = await prisma.stayNotice.create({ data: { stayId, message: parsed.data.message } })
  return NextResponse.json(notice, { status: 201 })
}
