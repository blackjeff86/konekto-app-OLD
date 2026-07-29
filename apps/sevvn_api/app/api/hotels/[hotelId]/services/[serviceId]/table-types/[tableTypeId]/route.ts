import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchTableTypeSchema = z.object({
  label: z.string().min(1).nullable().optional(),
  seats: z.number().int().min(1).optional(),
  quantity: z.number().int().min(0).optional(),
})

async function authorizeGerente(request: NextRequest, hotelId: string): Promise<NextResponse | null> {
  try {
    const staff = await requireStaffRole(request, ['gerente'])
    if (staff.hotelId !== hotelId) {
      return NextResponse.json({ error: 'forbidden' }, { status: 403 })
    }
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  return null
}

async function findTableTypeForHotel(hotelId: string, serviceId: string, tableTypeId: string) {
  return prisma.restaurantTableType.findFirst({
    where: { id: tableTypeId, serviceId, service: { hotelId } },
  })
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string; tableTypeId: string }> },
) {
  const { hotelId, serviceId, tableTypeId } = await params

  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const parsed = patchTableTypeSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await findTableTypeForHotel(hotelId, serviceId, tableTypeId)
  if (!existing) {
    return NextResponse.json({ error: 'table_type_not_found' }, { status: 404 })
  }

  const updated = await prisma.restaurantTableType.update({
    where: { id: tableTypeId },
    data: parsed.data,
  })
  return NextResponse.json(updated)
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string; tableTypeId: string }> },
) {
  const { hotelId, serviceId, tableTypeId } = await params

  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const existing = await findTableTypeForHotel(hotelId, serviceId, tableTypeId)
  if (!existing) {
    return NextResponse.json({ error: 'table_type_not_found' }, { status: 404 })
  }

  await prisma.restaurantTableType.delete({ where: { id: tableTypeId } })
  return NextResponse.json({ success: true })
}
