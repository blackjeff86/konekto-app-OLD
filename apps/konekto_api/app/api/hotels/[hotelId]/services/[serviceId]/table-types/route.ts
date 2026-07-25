import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const createTableTypeSchema = z.object({
  label: z.string().min(1).nullable().optional(),
  seats: z.number().int().min(1),
  quantity: z.number().int().min(0),
})

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params

  const service = await prisma.service.findUnique({ where: { id: serviceId, hotelId } })
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  const tableTypes = await prisma.restaurantTableType.findMany({ where: { serviceId } })
  return NextResponse.json(tableTypes)
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params

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

  const service = await prisma.service.findUnique({ where: { id: serviceId, hotelId } })
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }
  if (service.type !== 'restaurant') {
    return NextResponse.json({ error: 'not_a_restaurant' }, { status: 400 })
  }

  const parsed = createTableTypeSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const tableType = await prisma.restaurantTableType.create({
    data: { serviceId, ...parsed.data },
  })
  return NextResponse.json(tableType, { status: 201 })
}
