import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchPartnerSchema = z.object({
  name: z.string().trim().min(1).optional(),
  contactName: z.string().trim().min(1).nullable().optional(),
  phone: z.string().trim().min(1).nullable().optional(),
  email: z.string().trim().email().nullable().optional(),
  notes: z.string().trim().min(1).nullable().optional(),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; partnerId: string }> },
) {
  const { hotelId, partnerId } = await params

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

  const parsed = patchPartnerSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.partner.findFirst({ where: { id: partnerId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'partner_not_found' }, { status: 404 })
  }

  const partner = await prisma.partner.update({ where: { id: partnerId }, data: parsed.data })
  return NextResponse.json(partner)
}

// Só remove se nenhum item do catálogo ainda estiver vinculado a esse
// parceiro — evita um item ficar com `paymentMode: partner` órfão de
// parceiro. O gerente precisa desvincular os itens primeiro.
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; partnerId: string }> },
) {
  const { hotelId, partnerId } = await params

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

  const existing = await prisma.partner.findFirst({ where: { id: partnerId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'partner_not_found' }, { status: 404 })
  }

  const usageCount = await prisma.serviceItem.count({ where: { partnerId } })
  if (usageCount > 0) {
    return NextResponse.json({ error: 'partner_in_use' }, { status: 409 })
  }

  await prisma.partner.delete({ where: { id: partnerId } })
  return NextResponse.json({ success: true })
}
