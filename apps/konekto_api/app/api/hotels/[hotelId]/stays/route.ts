import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Lista as estadias (reservas de quarto) do hotel — tela "Quartos" do
// portal. Traz os hóspedes de cada uma (nome + status) pra já mostrar
// quantas pessoas tem em cada quarto sem precisar de uma segunda chamada.
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

  const stays = await prisma.stay.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'desc' },
    include: { guests: { select: { id: true, firstName: true, lastName: true, status: true } } },
  })
  return NextResponse.json(stays)
}

const createStaySchema = z.object({
  roomNumber: z.string().min(1),
  checkInDate: z.coerce.date(),
  checkOutDate: z.coerce.date(),
})

// Cria a reserva do quarto — passo 1 antes de adicionar qualquer hóspede
// (cada pessoa é criada depois via `POST /api/hotels/:hotelId/guests`
// referenciando esta Stay pelo `stayId`).
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

  const parsed = createStaySchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const stay = await prisma.stay.create({ data: { hotelId, ...parsed.data } })
  return NextResponse.json(stay, { status: 201 })
}
