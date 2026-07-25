import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Chat da estadia do hóspede autenticado — mesma conversa é compartilhada
// por todo mundo hospedado no mesmo quarto (não é 1:1 por hóspede). O
// token do hóspede não carrega `stayId` diretamente, então resolve pelo
// próprio registro do Guest (mesmo padrão de /api/guest/notices).
export async function GET(request: NextRequest) {
  let guestPayload
  try {
    guestPayload = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const guest = await prisma.guest.findUnique({ where: { id: guestPayload.sub }, select: { stayId: true } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const messages = await prisma.stayMessage.findMany({
    where: { stayId: guest.stayId },
    orderBy: { createdAt: 'asc' },
    include: { guest: { select: { firstName: true, lastName: true } } },
  })
  return NextResponse.json(messages)
}

const sendMessageSchema = z.object({ message: z.string().trim().min(1).max(1000) })

export async function POST(request: NextRequest) {
  let guestPayload
  try {
    guestPayload = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = sendMessageSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const guest = await prisma.guest.findUnique({ where: { id: guestPayload.sub }, select: { stayId: true } })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const message = await prisma.stayMessage.create({
    data: {
      stayId: guest.stayId,
      senderType: 'guest',
      guestId: guestPayload.sub,
      body: parsed.data.message,
      readByGuest: true,
      readByStaff: false,
    },
  })
  return NextResponse.json(message, { status: 201 })
}
