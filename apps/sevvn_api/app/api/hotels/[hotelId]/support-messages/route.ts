import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Conversa de suporte do hotel com a Sevvn — diferente de StayMessage
// (guest<->staff, por estadia), essa é por HOTEL inteiro, staff<->plataforma.
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

  const messages = await prisma.platformSupportMessage.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'asc' },
  })
  return NextResponse.json(messages)
}

const sendMessageSchema = z.object({ message: z.string().trim().min(1).max(2000) })

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

  const parsed = sendMessageSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const message = await prisma.platformSupportMessage.create({
    data: {
      hotelId,
      senderType: 'hotel',
      staffId: staff.sub,
      body: parsed.data.message,
      readByHotel: true,
      readByPlatform: false,
    },
  })
  return NextResponse.json(message, { status: 201 })
}
