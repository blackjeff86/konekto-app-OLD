import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchItemSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  price: z.number().nullable().optional(),
  imageUrl: z.string().min(1).nullable().optional(),
  location: z.string().min(1).nullable().optional(),
  category: z.string().min(1).nullable().optional(),
  extraInfo: z.string().min(1).nullable().optional(),
  position: z.number().int().min(0).optional(),
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

async function findItemForHotel(hotelId: string, serviceId: string, itemId: string) {
  return prisma.serviceItem.findFirst({
    where: { id: itemId, serviceId, service: { hotelId } },
  })
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string; itemId: string }> },
) {
  const { hotelId, serviceId, itemId } = await params

  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const parsed = patchItemSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await findItemForHotel(hotelId, serviceId, itemId)
  if (!existing) {
    return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
  }

  const updated = await prisma.serviceItem.update({
    where: { id: itemId },
    data: parsed.data,
  })
  return NextResponse.json(updated)
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string; itemId: string }> },
) {
  const { hotelId, serviceId, itemId } = await params

  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const existing = await findItemForHotel(hotelId, serviceId, itemId)
  if (!existing) {
    return NextResponse.json({ error: 'item_not_found' }, { status: 404 })
  }

  await prisma.serviceItem.delete({ where: { id: itemId } })
  return NextResponse.json({ success: true })
}
