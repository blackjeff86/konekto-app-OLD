import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import type { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { autoTranslateOrNull } from '@/lib/translate'
import { validateSchedulingFields } from '@/lib/scheduling'
import { validatePartnerPaymentMode } from '@/lib/partner-payment'

export const runtime = 'nodejs'

const translationFieldsSchema = z.object({
  en: z.record(z.string(), z.string()).optional(),
  es: z.record(z.string(), z.string()).optional(),
})

const patchItemSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  price: z.number().nullable().optional(),
  imageUrl: z.string().min(1).nullable().optional(),
  location: z.string().min(1).nullable().optional(),
  category: z.string().min(1).nullable().optional(),
  extraInfo: z.string().min(1).nullable().optional(),
  position: z.number().int().min(0).optional(),
  durationMinutes: z.number().int().positive().nullable().optional(),
  capacityPerSlot: z.number().int().positive().nullable().optional(),
  availableDaysOfWeek: z.array(z.number().int().min(1).max(7)).optional(),
  availabilityStartMinute: z.number().int().min(0).max(1439).nullable().optional(),
  availabilityEndMinute: z.number().int().min(1).max(1440).nullable().optional(),
  isMinibarItem: z.boolean().optional(),
  partnerId: z.string().min(1).nullable().optional(),
  paymentMode: z.enum(['hotel', 'partner']).optional(),
  // Mesma regra do serviço: presença desta chave = edição manual no
  // portal, desliga a tradução automática futura desse item.
  translations: translationFieldsSchema.optional(),
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

  // PATCH é parcial — precisa validar a config de agendamento resultante
  // (existente + o que veio no body), não só os campos que o body trouxe,
  // senão dá pra desabilitar `capacityPerSlot` sozinho e deixar
  // `durationMinutes` órfão sem os outros campos obrigatórios junto.
  const schedulingCheck = validateSchedulingFields({
    durationMinutes: parsed.data.durationMinutes !== undefined ? parsed.data.durationMinutes : existing.durationMinutes,
    capacityPerSlot: parsed.data.capacityPerSlot !== undefined ? parsed.data.capacityPerSlot : existing.capacityPerSlot,
    availableDaysOfWeek: parsed.data.availableDaysOfWeek !== undefined ? parsed.data.availableDaysOfWeek : existing.availableDaysOfWeek,
    availabilityStartMinute:
      parsed.data.availabilityStartMinute !== undefined ? parsed.data.availabilityStartMinute : existing.availabilityStartMinute,
    availabilityEndMinute:
      parsed.data.availabilityEndMinute !== undefined ? parsed.data.availabilityEndMinute : existing.availabilityEndMinute,
  })
  if (!schedulingCheck.ok) {
    return NextResponse.json({ error: schedulingCheck.error }, { status: 400 })
  }

  // Mesmo racional acima: `paymentMode: partner` só é válido se o item
  // ACABAR com um `partnerId` — existente ou vindo no body.
  const partnerCheck = validatePartnerPaymentMode({
    partnerId: parsed.data.partnerId !== undefined ? parsed.data.partnerId : existing.partnerId,
    paymentMode: parsed.data.paymentMode !== undefined ? parsed.data.paymentMode : existing.paymentMode,
  })
  if (!partnerCheck.ok) {
    return NextResponse.json({ error: partnerCheck.error }, { status: 400 })
  }

  if (parsed.data.partnerId) {
    const partner = await prisma.partner.findFirst({ where: { id: parsed.data.partnerId, hotelId } })
    if (!partner) {
      return NextResponse.json({ error: 'partner_not_found' }, { status: 400 })
    }
  }

  const { translations: manualTranslations, ...rest } = parsed.data
  const updateData: Prisma.ServiceItemUpdateInput = { ...rest }

  const translatableFieldsChanged = ['name', 'description', 'location', 'category', 'extraInfo'].some(
    (field) => parsed.data[field as keyof typeof parsed.data] !== undefined,
  )

  if (manualTranslations) {
    updateData.translations = manualTranslations as Prisma.InputJsonValue
    updateData.translationsAutoGenerated = false
  } else if (translatableFieldsChanged && existing.translationsAutoGenerated) {
    const autoTranslations = await autoTranslateOrNull({
      name: parsed.data.name ?? existing.name,
      description: parsed.data.description ?? existing.description,
      location: parsed.data.location !== undefined ? parsed.data.location : existing.location,
      category: parsed.data.category !== undefined ? parsed.data.category : existing.category,
      extraInfo: parsed.data.extraInfo !== undefined ? parsed.data.extraInfo : existing.extraInfo,
    })
    if (autoTranslations) {
      updateData.translations = autoTranslations as Prisma.InputJsonValue
    }
  }

  const updated = await prisma.serviceItem.update({
    where: { id: itemId },
    data: updateData,
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
