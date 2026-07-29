import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'
import { buildHotelOverview } from '@/lib/platform-admin-hotel-shape'
import { isModuleId } from '@/lib/module-catalog'
import { recordPlatformAdminAudit } from '@/lib/platform-admin-audit'
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

const patchModulesSchema = z.object({
  // Lista COMPLETA de módulos de cortesia (substitui, não faz merge item a
  // item) — o toggle no konekto_admin sempre manda o conjunto inteiro
  // marcado na tela, mesmo padrão de outras listas substituídas por
  // inteiro neste projeto (ex: promoImages.images). Nunca inclui os
  // módulos que o Plan Preset do hotel já dá por padrão (ver
  // resolveHotelModules em lib/module-engine.ts) — só as extras de
  // cortesia. Renomeado de `enabledFeatures`.
  extraModules: z.array(z.string().refine(isModuleId, { message: 'unknown_module' })),
})

interface HotelConfigShape {
  extraModules?: string[]
  [key: string]: unknown
}

// Só a equipe Sevvn habilita um módulo Premium como cortesia pra um hotel
// de plano mais baixo — de propósito não existe rota equivalente no
// portal do hotel (o próprio hotel não escolhe módulos fora do que o
// plano permite).
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  let admin
  try {
    admin = await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = patchModulesSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const updatedConfig: HotelConfigShape = {
    ...(hotel.config as HotelConfigShape),
    extraModules: parsed.data.extraModules,
  }

  const updated = await prisma.$transaction(async (tx) => {
    const nextHotel = await tx.hotel.update({
      where: { id: hotelId },
      data: { config: updatedConfig as unknown as Prisma.InputJsonValue },
    })
    await recordPlatformAdminAudit(tx, {
      action: 'platform_admin.hotel.extra_modules_updated',
      admin,
      hotelId,
      payload: {
        extraModules: parsed.data.extraModules,
      },
      request,
      targetId: hotelId,
      targetType: 'hotel',
    })
    return nextHotel
  })

  return NextResponse.json(updated.config)
}
