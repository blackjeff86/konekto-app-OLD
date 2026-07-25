import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import type { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { autoTranslateOrNull } from '@/lib/translate'
import { validateSchedulingFields } from '@/lib/scheduling'
import { validatePartnerPaymentMode } from '@/lib/partner-payment'

export const runtime = 'nodejs'

const createItemSchema = z
  .object({
    name: z.string().min(1),
    description: z.string(),
    price: z.number().nullable().optional(),
    imageUrl: z.string().min(1).nullable().optional(),
    location: z.string().min(1).nullable().optional(),
    category: z.string().min(1).nullable().optional(),
    extraInfo: z.string().min(1).nullable().optional(),
    durationMinutes: z.number().int().positive().nullable().optional(),
    capacityPerSlot: z.number().int().positive().nullable().optional(),
    availableDaysOfWeek: z.array(z.number().int().min(1).max(7)).optional(),
    availabilityStartMinute: z.number().int().min(0).max(1439).nullable().optional(),
    availabilityEndMinute: z.number().int().min(1).max(1440).nullable().optional(),
    isMinibarItem: z.boolean().optional(),
    partnerId: z.string().min(1).nullable().optional(),
    paymentMode: z.enum(['hotel', 'partner']).optional(),
  })
  .superRefine((data, ctx) => {
    const schedulingResult = validateSchedulingFields(data)
    if (!schedulingResult.ok) {
      ctx.addIssue({ code: 'custom', message: schedulingResult.error })
    }
    const partnerResult = validatePartnerPaymentMode(data)
    if (!partnerResult.ok) {
      ctx.addIssue({ code: 'custom', message: partnerResult.error })
    }
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

  if (parsed.data.partnerId) {
    const partner = await prisma.partner.findFirst({ where: { id: parsed.data.partnerId, hotelId } })
    if (!partner) {
      return NextResponse.json({ error: 'partner_not_found' }, { status: 400 })
    }
  }

  const maxPosition = await prisma.serviceItem.aggregate({
    where: { serviceId },
    _max: { position: true },
  })
  const nextPosition = (maxPosition._max.position ?? -1) + 1

  const translations = await autoTranslateOrNull({
    name: parsed.data.name,
    description: parsed.data.description,
    location: parsed.data.location,
    category: parsed.data.category,
    extraInfo: parsed.data.extraInfo,
  })

  const item = await prisma.serviceItem.create({
    data: { serviceId, position: nextPosition, ...parsed.data, translations: (translations ?? undefined) as Prisma.InputJsonValue | undefined },
  })
  return NextResponse.json(item, { status: 201 })
}
