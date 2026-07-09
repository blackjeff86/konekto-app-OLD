import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchOrderSchema = z.object({
  status: z.enum(['pending', 'in_progress', 'completed', 'cancelled']),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; orderId: string }> },
) {
  const { hotelId, orderId } = await params

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

  const parsed = patchOrderSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.order.findUnique({ where: { id: orderId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'order_not_found' }, { status: 404 })
  }

  const updated = await prisma.order.update({ where: { id: orderId }, data: { status: parsed.data.status } })
  return NextResponse.json(updated)
}
