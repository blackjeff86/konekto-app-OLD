import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { flattenStayRoomNumber } from '@/lib/stay-shape'
import { generateAccessCode } from '@/lib/guest-access-code'
import { sweepExpiredStays } from '@/lib/stay-expiration'

export const runtime = 'nodejs'

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

  await sweepExpiredStays(hotelId)

  const guests = await prisma.guest.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'desc' },
    include: {
      stay: { select: { room: { select: { number: true } }, checkInDate: true, checkOutDate: true, status: true } },
    },
  })
  return NextResponse.json(guests.map((guest) => ({ ...guest, stay: flattenStayRoomNumber(guest.stay) })))
}

const createGuestSchema = z.object({
  stayId: z.string().min(1),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  documentType: z.enum(['cpf', 'passport', 'other']),
  documentNumber: z.string().min(1),
  phoneCountryCode: z.string().min(1),
  phoneNumber: z.string().min(1),
  whatsappCountryCode: z.string().min(1).optional(),
  whatsappNumber: z.string().min(1).optional(),
  email: z.string().email().optional(),
  address: z.string().min(1).optional(),
  country: z.string().min(1),
  wifiPassword: z.string().min(1).optional(),
})

// Todo hóspede pertence a uma `Stay` já existente (o quarto/reserva) — a
// recepção cria a Stay primeiro (ver `/api/hotels/:hotelId/stays`) e só
// depois adiciona cada pessoa dentro dela. Isso é o que permite vários
// hóspedes (marido, esposa, filhos) com códigos individuais, todos
// centralizados no mesmo quarto.
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

  const parsed = createGuestSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const stay = await prisma.stay.findFirst({ where: { id: parsed.data.stayId, hotelId } })
  if (!stay) {
    return NextResponse.json({ error: 'stay_not_found' }, { status: 404 })
  }

  const guest = await prisma.guest.create({
    data: { hotelId, ...parsed.data, accessCode: generateAccessCode(hotelId) },
    include: {
      stay: { select: { room: { select: { number: true } }, checkInDate: true, checkOutDate: true, status: true } },
    },
  })
  return NextResponse.json({ ...guest, stay: flattenStayRoomNumber(guest.stay) }, { status: 201 })
}
