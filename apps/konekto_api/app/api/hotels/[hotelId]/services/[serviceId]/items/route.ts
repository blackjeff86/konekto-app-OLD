import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const createItemSchema = z.object({
  name: z.string().min(1),
  description: z.string(),
  price: z.number().nullable().optional(),
  imageUrl: z.string().min(1).nullable().optional(),
  location: z.string().min(1).nullable().optional(),
  category: z.string().min(1).nullable().optional(),
  extraInfo: z.string().min(1).nullable().optional(),
})

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

  const parsed = createItemSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const maxPosition = await prisma.serviceItem.aggregate({
    where: { serviceId },
    _max: { position: true },
  })
  const nextPosition = (maxPosition._max.position ?? -1) + 1

  const item = await prisma.serviceItem.create({
    data: { serviceId, position: nextPosition, ...parsed.data },
  })
  return NextResponse.json(item, { status: 201 })
}
