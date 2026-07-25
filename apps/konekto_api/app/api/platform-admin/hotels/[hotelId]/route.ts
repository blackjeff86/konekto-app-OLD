import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'
import { buildHotelOverview } from '@/lib/platform-admin-hotel-shape'
import { FEATURE_FLAGS } from '@/lib/feature-flags'
import type { Prisma } from '@/app/generated/prisma/client'

export const runtime = 'nodejs'

// Detalhamento de um hotel cliente — tudo que a lista já tem, mais a
// equipe (staff) com acesso admin ao portal daquele hotel.
export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const [overview, staff] = await Promise.all([
    buildHotelOverview(hotel),
    prisma.staff.findMany({
      where: { hotelId },
      select: { id: true, name: true, email: true, role: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    }),
  ])

  return NextResponse.json({ ...overview, staff })
}

const patchFeaturesSchema = z.object({
  // Lista COMPLETA de flags de cortesia (substitui, não faz merge item a
  // item) — o toggle no konekto_admin sempre manda o conjunto inteiro
  // marcado na tela, mesmo padrão de outras listas substituídas por
  // inteiro neste projeto (ex: promoImages.images). Nunca inclui as flags
  // que o plano já dá por padrão (ver resolveEnabledFeatures em
  // lib/feature-flags.ts) — só as extras de cortesia.
  enabledFeatures: z.array(z.enum(FEATURE_FLAGS)),
})

interface HotelConfigShape {
  enabledFeatures?: string[]
  [key: string]: unknown
}

// Só a equipe Konekto habilita uma feature Premium como cortesia pra um
// hotel de plano mais baixo — de propósito não existe rota equivalente no
// `konekto_portal_next` (o próprio hotel não escolhe suas flags).
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = patchFeaturesSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const updatedConfig: HotelConfigShape = {
    ...(hotel.config as HotelConfigShape),
    enabledFeatures: parsed.data.enabledFeatures,
  }

  const updated = await prisma.hotel.update({
    where: { id: hotelId },
    data: { config: updatedConfig as unknown as Prisma.InputJsonValue },
  })

  return NextResponse.json(updated.config)
}
