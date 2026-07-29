import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Lista de gestão do portal — sempre exige staff do próprio hotel e mostra
// todos os cupons (ativos, desativados, expirados). O que o hóspede
// enxerga é um endpoint separado (`GET /api/coupons`, autenticado por
// guest), que já filtra por validade/elegibilidade.
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

  const coupons = await prisma.coupon.findMany({ where: { hotelId }, orderBy: { position: 'asc' } })
  return NextResponse.json(coupons)
}

const createCouponSchema = z.object({
  title: z.string().trim().min(1),
  description: z.string().trim().min(1),
  code: z
    .string()
    .trim()
    .min(1)
    .transform((value) => value.toUpperCase()),
  discountType: z.enum(['percentage', 'fixed_amount']),
  discountValue: z.number().positive(),
  minOrderValue: z.number().positive().optional(),
  imageUrl: z.string().trim().min(1).optional(),
  validFrom: z.coerce.date().optional(),
  validUntil: z.coerce.date().optional(),
  usageLimit: z.number().int().positive().optional(),
  perGuestLimit: z.number().int().positive().default(1),
})
  .refine((data) => data.discountType !== 'percentage' || data.discountValue <= 100, {
    message: 'discount_percentage_over_100',
    path: ['discountValue'],
  })

// Cadastro de cupom/promoção — só `gerente` (configuração estrutural do
// hotel, mesmo padrão de Serviços/Quartos).
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

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

  const parsed = createCouponSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  try {
    const coupon = await prisma.coupon.create({ data: { hotelId, ...parsed.data } })
    return NextResponse.json(coupon, { status: 201 })
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return NextResponse.json({ error: 'coupon_code_already_exists' }, { status: 409 })
    }
    throw error
  }
}
