import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { getPlanPreset } from '@/lib/plan-presets'
import { isModuleId, getModuleDefinition } from '@/lib/module-catalog'
import { validateModuleConfiguration } from '@/lib/module-registry'
import { resolveHotelModules, type HotelModulesConfig } from '@/lib/module-engine'
import type { Prisma } from '@/app/generated/prisma/client'

export const runtime = 'nodejs'

interface HotelConfigShape {
  hotelInfo?: Record<string, unknown>
  colorPalette?: Record<string, unknown>
  template?: string
  modules?: HotelModulesConfig
  /// Cortesia da equipe Konekto — só editável via platform-admin (ver
  /// app/api/platform-admin/hotels/[hotelId]/route.ts). Renomeado de
  /// `enabledFeatures`.
  extraModules?: string[]
  [key: string]: unknown
}

// Endpoint público (sem auth) — usado tanto pelo app do hóspede (busca de
// tema/config/módulos) quanto pelo portal (telas de Aparência e Módulos).
// `plan`/`allowedTemplates`/`enabledModules` são sempre derivados aqui
// (nunca guardados prontos em `Hotel.config`) pra manter uma única fonte de
// verdade em `HotelSubscription.presetId` — ninguém decide sozinho o que
// está disponível.
export async function GET(_request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }
  const subscription = await prisma.hotelSubscription.findUnique({ where: { hotelId } })
  const plan = subscription?.plan ?? 'essential'
  const presetId = subscription?.presetId ?? plan
  const preset = getPlanPreset(presetId)
  const config = hotel.config as HotelConfigShape

  return NextResponse.json({
    ...config,
    plan,
    allowedTemplates: preset.templateIds,
    enabledModules: resolveHotelModules(presetId, config.modules ?? {}, config.extraModules ?? []),
  })
}

const moduleStateSchema = z.object({
  enabled: z.boolean().optional(),
  configuration: z.record(z.string(), z.unknown()).optional(),
})

const patchHotelSchema = z.object({
  hotelInfo: z
    .object({
      name: z.string().min(1).optional(),
      logoUrl: z.string().min(1).optional(),
      // Endereço do hotel — usado só na tela "Mapa do local" do app do
      // hóspede (info estática de quarto/wifi/endereço, não um mapa de
      // verdade). Não confundir com Guest.address, que é o endereço do
      // hóspede.
      address: z.string().min(1).optional(),
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
  // Template White Label do app do hóspede — validado abaixo contra os
  // templates do Plan Preset do hotel (lib/plan-presets.ts), não só pela
  // lista de valores aceitos aqui.
  template: z.enum(['aura', 'bosque', 'elite', 'pulse', 'horizon']).optional(),
  // Configuração de Módulos (Fase 3 da arquitetura de módulos) — mapa
  // parcial por id: só os módulos que o hotel está de fato mudando nesta
  // chamada, mesclado (não substitui o mapa inteiro) sobre o que já existe.
  // Cada chave validada contra o catálogo + contra o preset do hotel
  // abaixo, `configuration` (quando presente) validada pelo configSchema do
  // Module Registry.
  modules: z.record(z.string(), moduleStateSchema).optional(),
})

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

  const subscription = await prisma.hotelSubscription.findUnique({ where: { hotelId } })
  const plan = subscription?.plan ?? 'essential'
  const presetId = subscription?.presetId ?? plan
  const preset = getPlanPreset(presetId)

  // Plan Preset decide quais templates o hotel pode escolher — validado
  // aqui (não só na UI do portal) porque é uma regra de acesso, não só de
  // apresentação.
  if (parsed.data.template && !preset.templateIds.includes(parsed.data.template)) {
    return NextResponse.json({ error: 'template_not_allowed_for_plan' }, { status: 403 })
  }

  const currentConfig = hotel.config as HotelConfigShape

  let updatedModules = currentConfig.modules
  if (parsed.data.modules) {
    const allowedModuleIds = new Set([...preset.moduleIds, ...(currentConfig.extraModules ?? [])])
    const nextModules: HotelModulesConfig = { ...currentConfig.modules }

    for (const [moduleId, state] of Object.entries(parsed.data.modules)) {
      if (!isModuleId(moduleId)) {
        return NextResponse.json({ error: 'unknown_module', moduleId }, { status: 400 })
      }
      if (!allowedModuleIds.has(moduleId)) {
        return NextResponse.json({ error: 'module_not_allowed_for_plan', moduleId }, { status: 403 })
      }
      if (state.configuration !== undefined) {
        const configSchemaId = getModuleDefinition(moduleId)?.configSchemaId
        if (!configSchemaId) {
          return NextResponse.json({ error: 'module_has_no_configuration', moduleId }, { status: 400 })
        }
        const validation = validateModuleConfiguration(configSchemaId, state.configuration)
        if (!validation.success) {
          return NextResponse.json({ error: validation.error, moduleId }, { status: 400 })
        }
      }
      nextModules[moduleId] = {
        enabled: state.enabled ?? nextModules[moduleId]?.enabled,
        configuration: state.configuration ?? nextModules[moduleId]?.configuration,
      }
    }
    updatedModules = nextModules
  }

  const updatedConfig: HotelConfigShape = {
    ...currentConfig,
    hotelInfo: { ...currentConfig.hotelInfo, ...parsed.data.hotelInfo },
    colorPalette: { ...currentConfig.colorPalette, ...parsed.data.colorPalette },
    template: parsed.data.template ?? currentConfig.template,
    modules: updatedModules,
  }

  const updated = await prisma.hotel.update({
    where: { id: hotelId },
    data: { config: updatedConfig as unknown as Prisma.InputJsonValue },
  })
  return NextResponse.json(updated.config)
}
