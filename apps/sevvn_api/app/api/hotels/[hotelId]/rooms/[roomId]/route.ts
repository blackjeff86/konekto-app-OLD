import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchRoomSchema = z.object({
  number: z.string().trim().min(1).optional(),
  description: z.string().trim().min(1).nullable().optional(),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; roomId: string }> },
) {
  const { hotelId, roomId } = await params

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

  const parsed = patchRoomSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.room.findFirst({ where: { id: roomId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'room_not_found' }, { status: 404 })
  }

  try {
    const room = await prisma.room.update({ where: { id: roomId }, data: parsed.data })
    return NextResponse.json(room)
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return NextResponse.json({ error: 'room_number_already_exists' }, { status: 409 })
    }
    throw error
  }
}

// Só remove se não tiver nenhuma Stay vinculada (histórico ou ativa) — um
// quarto com estadias já criadas fica "arquivado" implicitamente (não
// aparece mais pra criar Stay nova) em vez de removido, editando a
// descrição ou simplesmente não usando mais.
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; roomId: string }> },
) {
  const { hotelId, roomId } = await params

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

  const existing = await prisma.room.findFirst({ where: { id: roomId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'room_not_found' }, { status: 404 })
  }

  const stayCount = await prisma.stay.count({ where: { roomId } })
  if (stayCount > 0) {
    return NextResponse.json({ error: 'room_has_stays' }, { status: 409 })
  }

  await prisma.room.delete({ where: { id: roomId } })
  return NextResponse.json({ success: true })
}
