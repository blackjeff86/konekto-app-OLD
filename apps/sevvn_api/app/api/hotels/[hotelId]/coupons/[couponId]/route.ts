import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const patchCouponSchema = z
  .object({
    title: z.string().trim().min(1).optional(),
    description: z.string().trim().min(1).optional(),
    code: z
      .string()
      .trim()
      .min(1)
      .transform((value) => value.toUpperCase())
      .optional(),
    discountType: z.enum(['percentage', 'fixed_amount']).optional(),
    discountValue: z.number().positive().optional(),
    minOrderValue: z.number().positive().nullable().optional(),
    imageUrl: z.string().trim().min(1).nullable().optional(),
    validFrom: z.coerce.date().nullable().optional(),
    validUntil: z.coerce.date().nullable().optional(),
    usageLimit: z.number().int().positive().nullable().optional(),
    perGuestLimit: z.number().int().positive().optional(),
    enabled: z.boolean().optional(),
  })
  .refine(
    (data) =>
      data.discountType !== 'percentage' || data.discountValue == null || data.discountValue <= 100,
    { message: 'discount_percentage_over_100', path: ['discountValue'] },
  )

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; couponId: string }> },
) {
  const { hotelId, couponId } = await params

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

  const parsed = patchCouponSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.coupon.findFirst({ where: { id: couponId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'coupon_not_found' }, { status: 404 })
  }

  try {
    const coupon = await prisma.coupon.update({ where: { id: couponId }, data: parsed.data })
    return NextResponse.json(coupon)
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return NextResponse.json({ error: 'coupon_code_already_exists' }, { status: 409 })
    }
    throw error
  }
}

// Só remove se o cupom nunca tiver sido usado em nenhum pedido — mesmo
// padrão de Room/Service: um cupom já usado fica "arquivado" desativando
// (`enabled: false`) em vez de apagado, pra preservar o histórico do
// pedido que o usou.
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; couponId: string }> },
) {
  const { hotelId, couponId } = await params

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

  const existing = await prisma.coupon.findFirst({ where: { id: couponId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'coupon_not_found' }, { status: 404 })
  }

  const usageCount = await prisma.order.count({ where: { couponId } })
  if (usageCount > 0) {
    return NextResponse.json({ error: 'coupon_already_used' }, { status: 409 })
  }

  await prisma.coupon.delete({ where: { id: couponId } })
  return NextResponse.json({ success: true })
}
