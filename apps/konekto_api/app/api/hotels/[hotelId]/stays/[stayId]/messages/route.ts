import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const sendMessageSchema = z.object({ message: z.string().trim().min(1).max(1000) })

// Recepção manda uma mensagem de chat pra todos os hóspedes da estadia
// (não é mais um aviso só-leitura — o hóspede pode responder, ver
// GET /api/guest/messages e POST /api/guest/messages).
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

  const parsed = sendMessageSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const stay = await prisma.stay.findFirst({ where: { id: stayId, hotelId } })
  if (!stay) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }

  const message = await prisma.stayMessage.create({
    data: {
      stayId,
      senderType: 'staff',
      body: parsed.data.message,
      readByStaff: true,
      readByGuest: false,
    },
  })
  return NextResponse.json(message, { status: 201 })
}
