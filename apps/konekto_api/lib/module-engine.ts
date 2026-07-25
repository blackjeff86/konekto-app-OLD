/// Module Engine — função pura que resolve QUAIS módulos estão ativos pra
/// um hotel, combinando Plan Preset (lib/plan-presets.ts) + configuração do
/// hotel (Hotel.config.modules). Não decide layout, navegação ou tema —
/// isso é responsabilidade das camadas de cima (Home Layout Engine,
/// Navigation Engine, Theme Engine, todas do lado Flutter).
import { getPlanPreset } from './plan-presets'
import { MODULE_CATALOG } from './module-catalog'

export interface HotelModuleState {
  /// Ausente = usa o default do Plan Preset (permitido = ligado). Hotel só
  /// pode DESLIGAR um módulo que o plano já permite (opt-out) — nunca ligar
  /// um módulo fora do preset por conta própria (isso é `extraModules`,
  /// cortesia da equipe Konekto).
  enabled?: boolean
  configuration?: Record<string, unknown>
}

export type HotelModulesConfig = Record<string, HotelModuleState>

export interface ResolvedModule {
  id: string
  enabled: boolean
  configuration: Record<string, unknown>
}

/// `extraModuleIds` = cortesia da equipe Konekto (`Hotel.config.extraModules`,
/// renomeado de `enabledFeatures`) — só ADICIONA módulos além do preset,
/// nunca remove um que o preset já dá de graça (mesma regra que
/// `resolveEnabledFeatures` já garantia antes desta migração).
export function resolveHotelModules(
  presetId: string,
  hotelModules: HotelModulesConfig = {},
  extraModuleIds: string[] = [],
): ResolvedModule[] {
  const preset = getPlanPreset(presetId)
  const allowedIds = new Set([...preset.moduleIds, ...extraModuleIds])

  return MODULE_CATALOG.filter((module) => allowedIds.has(module.id)).map((module) => {
    const state = hotelModules[module.id]
    return {
      id: module.id,
      enabled: state?.enabled ?? true,
      configuration: state?.configuration ?? {},
    }
  })
}

export function resolveAllowedTemplates(presetId: string): readonly string[] {
  return getPlanPreset(presetId).templateIds
}
