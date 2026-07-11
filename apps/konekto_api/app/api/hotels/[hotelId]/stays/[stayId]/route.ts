import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { flattenStayRoomNumber } from '@/lib/stay-shape'

export const runtime = 'nodejs'

// Detalhe de uma estadia — todos os hóspedes vinculados (cada um com seus
// próprios pedidos/reservas) pra tela de detalhe de "Quartos" no portal.
// Os pedidos aninhados por hóspede também alimentam o resumo de consumo
// mostrado antes de "fechar a conta".
export async function GET(
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

  const stay = await prisma.stay.findFirst({
    where: { id: stayId, hotelId },
    include: {
      room: { select: { number: true } },
      guests: { include: { orders: { orderBy: { createdAt: 'desc' } } } },
      notices: { orderBy: { createdAt: 'desc' } },
    },
  })
  if (!stay) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }
  return NextResponse.json(flattenStayRoomNumber(stay))
}

const patchStaySchema = z
  .object({
    roomId: z.string().min(1).optional(),
    checkInDate: z.coerce.date().optional(),
    checkOutDate: z.coerce.date().optional(),
    close: z.boolean().optional(),
  })
  .refine(
    (data) => data.close || data.roomId !== undefined || data.checkInDate !== undefined || data.checkOutDate !== undefined,
    { message: 'no_fields_to_update' },
  )

// `close: true` fecha a conta do quarto inteiro: marca a Stay como
// `closed` e revoga (`status: revoked`) o código de acesso de todos os
// hóspedes vinculados a ela, numa única transação — depois disso nenhum
// deles consegue mais logar no app do hóspede com aquele código.
export async function PATCH(
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

  const parsed = patchStaySchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.stay.findFirst({ where: { id: stayId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }

  if (parsed.data.close) {
    const [stay] = await prisma.$transaction([
      prisma.stay.update({
        where: { id: stayId },
        data: { status: 'closed' },
        include: { room: { select: { number: true } } },
      }),
      prisma.guest.updateMany({ where: { stayId }, data: { status: 'revoked' } }),
    ])
    return NextResponse.json(flattenStayRoomNumber(stay))
  }

  if (parsed.data.roomId !== undefined) {
    const room = await prisma.room.findFirst({ where: { id: parsed.data.roomId, hotelId } })
    if (!room) {
      return NextResponse.json({ error: 'room_not_found' }, { status: 404 })
    }
  }

  const stay = await prisma.stay.update({
    where: { id: stayId },
    data: {
      ...(parsed.data.roomId !== undefined ? { roomId: parsed.data.roomId } : {}),
      ...(parsed.data.checkInDate !== undefined ? { checkInDate: parsed.data.checkInDate } : {}),
      ...(parsed.data.checkOutDate !== undefined ? { checkOutDate: parsed.data.checkOutDate } : {}),
    },
    include: { room: { select: { number: true } } },
  })
  return NextResponse.json(flattenStayRoomNumber(stay))
}
