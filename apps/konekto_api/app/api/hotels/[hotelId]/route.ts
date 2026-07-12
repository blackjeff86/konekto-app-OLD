import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import type { Prisma } from '@/app/generated/prisma/client'

export const runtime = 'nodejs'

export async function GET(_request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }
  return NextResponse.json(hotel.config)
}

const patchHotelSchema = z.object({
  hotelInfo: z
    .object({
      name: z.string().min(1).optional(),
      logoUrl: z.string().min(1).optional(),
      // Carrossel de imagens de destaque na home do hóspede — substitui o
      // objeto inteiro quando enviado (não dá pra adicionar/remover uma
      // imagem isolada via PATCH parcial, o portal sempre manda a lista
      // completa já editada).
      promoImages: z
        .object({
          images: z.array(z.string().min(1)).min(1),
          carouselHeight: z.number().positive().optional(),
          carouselEnabled: z.boolean().optional(),
        })
        .optional(),
    })
    .optional(),
  colorPalette: z.object({ primary: z.string().min(1).optional(), secondary: z.string().min(1).optional() }).optional(),
})

interface HotelConfigShape {
  hotelInfo?: Record<string, unknown>
  colorPalette?: Record<string, unknown>
  [key: string]: unknown
}

export async function PATCH(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
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

  const parsed = patchHotelSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const currentConfig = hotel.config as HotelConfigShape
  const updatedConfig: HotelConfigShape = {
    ...currentConfig,
    hotelInfo: { ...currentConfig.hotelInfo, ...parsed.data.hotelInfo },
    colorPalette: { ...currentConfig.colorPalette, ...parsed.data.colorPalette },
  }

  const updated = await prisma.hotel.update({
    where: { id: hotelId },
    data: { config: updatedConfig as unknown as Prisma.InputJsonValue },
  })
  return NextResponse.json(updated.config)
}
