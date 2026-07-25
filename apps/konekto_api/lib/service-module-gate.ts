import { prisma } from '@/lib/prisma'
import { getPlanPreset } from '@/lib/plan-presets'
import { resolveHotelModules, type HotelModulesConfig } from '@/lib/module-engine'

interface HotelConfigShape {
  modules?: HotelModulesConfig
  extraModules?: string[]
  [key: string]: unknown
}

/// Fase 12 — gating do catálogo de Serviços por módulo. `Service.moduleId`
/// existente (`null`) nunca é filtrado (fail-open) — só serviço com
/// `moduleId` setado é checado contra o que o hotel tem de fato resolvido
/// (preset + extras − desligado).
export async function resolveHotelEnabledModuleIds(hotelId: string): Promise<Set<string>> {
  const [hotel, subscription] = await Promise.all([
    prisma.hotel.findUnique({ where: { id: hotelId }, select: { config: true } }),
    prisma.hotelSubscription.findUnique({ where: { hotelId } }),
  ])
  const config = (hotel?.config ?? {}) as HotelConfigShape
  const plan = subscription?.plan ?? 'essential'
  const presetId = subscription?.presetId ?? plan
  const resolved = resolveHotelModules(presetId, config.modules ?? {}, config.extraModules ?? [])
  return new Set(resolved.filter((module) => module.enabled).map((module) => module.id))
}

export function isServiceModuleAllowed(moduleId: string, enabledModuleIds: Set<string>): boolean {
  return enabledModuleIds.has(moduleId)
}

/// `preset.moduleIds` (sem considerar desligado pelo hotel) — usado na
/// criação de Service: o gerente pode criar um serviço de um módulo que
/// ele mesmo desligou temporariamente (fica oculto até religar), mas não
/// de um módulo que o plano nunca liberou.
export async function resolveHotelAllowedModuleIds(hotelId: string): Promise<Set<string>> {
  const subscription = await prisma.hotelSubscription.findUnique({ where: { hotelId } })
  const plan = subscription?.plan ?? 'essential'
  const presetId = subscription?.presetId ?? plan
  return new Set(getPlanPreset(presetId).moduleIds)
}
