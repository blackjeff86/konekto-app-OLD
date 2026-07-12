import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Lista todos os quartos cadastrados do hotel, cada um já com a estadia
// ATIVA (se tiver) + hóspedes + pedidos — dá pro mapa de quartos (livre
// vs. ocupado, e o valor em aberto de quem está ocupando) sem precisar de
// uma segunda chamada por quarto.
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

  const rooms = await prisma.room.findMany({
    where: { hotelId },
    orderBy: { number: 'asc' },
    include: {
      stays: {
        where: { status: 'active' },
        take: 1,
        include: { guests: { include: { orders: { include: { coupon: { select: { title: true } } } } } } },
      },
    },
  })

  const shaped = rooms.map((room) => {
    const { stays, ...rest } = room
    return { ...rest, activeStay: stays[0] ?? null }
  })
  return NextResponse.json(shaped)
}

const createRoomSchema = z.object({
  number: z.string().trim().min(1),
  description: z.string().trim().min(1).optional(),
})

// Cadastro de quarto físico — feito em Configurações, só `gerente` (mesmo
// padrão de Serviços: é configuração estrutural do hotel, não operação do
// dia a dia da recepção).
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

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

  const parsed = createRoomSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  try {
    const room = await prisma.room.create({ data: { hotelId, ...parsed.data } })
    return NextResponse.json(room, { status: 201 })
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return NextResponse.json({ error: 'room_number_already_exists' }, { status: 409 })
    }
    throw error
  }
}
