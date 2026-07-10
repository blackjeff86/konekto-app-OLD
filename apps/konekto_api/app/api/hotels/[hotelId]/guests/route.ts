import crypto from 'node:crypto'
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Prefixo derivado do próprio hotelId (ex: "hotel_1" -> "HOTEL1") — não
// resolve unicidade sozinho (a coluna já é @unique), é só pra deixar
// auditável a olho nu de qual hotel é cada código, evitando qualquer
// confusão entre códigos de hotéis diferentes.
function hotelTag(hotelId: string): string {
  return hotelId.toUpperCase().replace(/[^A-Z0-9]/g, '')
}

function generateAccessCode(hotelId: string): string {
  return `${hotelTag(hotelId)}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`
}

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

  const guests = await prisma.guest.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'desc' },
  })
  return NextResponse.json(guests)
}

const createGuestSchema = z.object({
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
  checkInDate: z.coerce.date(),
  checkOutDate: z.coerce.date(),
  roomNumber: z.string().min(1),
  wifiPassword: z.string().min(1).optional(),
})

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

  const guest = await prisma.guest.create({
    data: { hotelId, ...parsed.data, accessCode: generateAccessCode(hotelId) },
  })
  return NextResponse.json(guest, { status: 201 })
}
