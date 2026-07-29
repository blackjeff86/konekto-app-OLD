import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { flattenStayRoomNumber } from '@/lib/stay-shape'

export const runtime = 'nodejs'

// Detalhe completo do hóspede — cadastro + estadia (quarto/datas) + todos
// os pedidos que ele já fez (serviço de quarto e reservas), pra tela de
// detalhe do portal (substitui o modal antigo).
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; guestId: string }> },
) {
  const { hotelId, guestId } = await params

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

  const guest = await prisma.guest.findFirst({
    where: { id: guestId, hotelId },
    include: {
      stay: {
        select: { id: true, room: { select: { number: true } }, checkInDate: true, checkOutDate: true, status: true },
      },
      orders: { orderBy: { createdAt: 'desc' } },
    },
  })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }
  return NextResponse.json({ ...guest, stay: flattenStayRoomNumber(guest.stay) })
}

const patchGuestSchema = z.object({
  firstName: z.string().min(1).optional(),
  lastName: z.string().min(1).optional(),
  documentType: z.enum(['cpf', 'passport', 'other']).optional(),
  documentNumber: z.string().min(1).optional(),
  phoneCountryCode: z.string().min(1).optional(),
  phoneNumber: z.string().min(1).optional(),
  whatsappCountryCode: z.string().min(1).nullable().optional(),
  whatsappNumber: z.string().min(1).nullable().optional(),
  email: z.string().email().nullable().optional(),
  address: z.string().min(1).nullable().optional(),
  country: z.string().min(1).optional(),
  wifiPassword: z.string().min(1).nullable().optional(),
})

// Edição do cadastro — dados pessoais só (nome, documento, contato). Não
// dá pra mudar `stayId`/quarto por aqui (mover um hóspede de quarto é uma
// operação diferente, fora de escopo agora) nem `accessCode`/`status`
// (esses têm seus próprios fluxos: revogar e o código gerado na criação).
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; guestId: string }> },
) {
  const { hotelId, guestId } = await params

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

  const parsed = patchGuestSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.guest.findFirst({ where: { id: guestId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const guest = await prisma.guest.update({
    where: { id: guestId },
    data: parsed.data,
    include: {
      stay: {
        select: { id: true, room: { select: { number: true } }, checkInDate: true, checkOutDate: true, status: true },
      },
      orders: { orderBy: { createdAt: 'desc' } },
    },
  })
  return NextResponse.json({ ...guest, stay: flattenStayRoomNumber(guest.stay) })
}

// Revoga em vez de apagar — preserva o registro pra quando Pedidos
// existir (um pedido vai referenciar um Guest).
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; guestId: string }> },
) {
  const { hotelId, guestId } = await params

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

  const existing = await prisma.guest.findUnique({ where: { id: guestId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const updated = await prisma.guest.update({ where: { id: guestId }, data: { status: 'revoked' } })
  return NextResponse.json(updated)
}
