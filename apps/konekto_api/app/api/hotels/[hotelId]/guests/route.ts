import crypto from 'node:crypto'
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

function generateAccessCode(): string {
  return crypto.randomBytes(5).toString('hex').toUpperCase()
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
  name: z.string().min(1),
  roomNumber: z.string().min(1),
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
    data: { hotelId, name: parsed.data.name, roomNumber: parsed.data.roomNumber, accessCode: generateAccessCode() },
  })
  return NextResponse.json(guest, { status: 201 })
}
