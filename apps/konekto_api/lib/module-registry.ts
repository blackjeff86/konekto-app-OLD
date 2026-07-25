/// Module Registry — Module Catalog (lib/module-catalog.ts) DESCREVE um
/// módulo; este arquivo diz COMO ele funciona: o schema de validação da
/// `configuration` do hotel pra esse módulo (ver Hotel.config.modules, Fase
/// 3), as capabilities configuráveis dentro dela, e os nomes de `actions`
/// que o módulo publica no Event Bus (Fase 2) — nunca uma chamada direta a
/// outro módulo.
///
/// Regra de ouro: módulo novo = configSchema aqui (se `implemented: true`
/// no Catalog) + Widget/Screen no lado Flutter
/// (`apps/konekto_mobile/lib/modules/module_registry.dart`). Nenhuma rota,
/// Module Engine ou camada acima muda.
import { z } from 'zod'

export interface ModuleCapabilityDefinition {
  id: string
  label: string
  default: boolean
}

export interface ModuleRegistryEntry {
  configSchema: z.ZodTypeAny
  capabilities: ModuleCapabilityDefinition[]
  /// Nomes de ação publicados no Event Bus quando o hóspede interage com o
  /// módulo (ex: 'addToOrder' publica o evento 'RoomServiceOrdered') — só
  /// os nomes, a lógica de publicação vive no lado Flutter.
  actions: string[]
}

const GENERIC_SERVICE_CAPABILITIES: ModuleCapabilityDefinition[] = [
  { id: 'acceptsOnlinePayment', label: 'Aceita pagamento online', default: false },
  { id: 'allowsScheduling', label: 'Permite agendamento', default: false },
  { id: 'allowsNotes', label: 'Permite observações', default: true },
  { id: 'acceptsImages', label: 'Aceita imagens', default: false },
  { id: 'allowsReview', label: 'Permite avaliação', default: false },
  { id: 'showsEstimatedTime', label: 'Exibe tempo estimado', default: false },
]

/// Configuration comum a todo módulo de Hospitalidade (ver `configuration`
/// de exemplo no plano de migração) — `capabilities` é sempre um mapa
/// parcial (`Partial<Record<capabilityId, boolean>>`), nunca preciso listar
/// todas: capability ausente usa o `default` declarado acima.
const genericServiceConfigSchema = z.object({
  title: z.string().trim().min(1).optional(),
  showOnHome: z.boolean().optional(),
  order: z.number().int().optional(),
  openingHours: z.string().trim().max(200).optional(),
  capabilities: z.record(z.string(), z.boolean()).optional(),
})

const homeCardConfigSchema = z.object({
  showOnHome: z.boolean().optional(),
  order: z.number().int().optional(),
})

export const MODULE_REGISTRY: Record<string, ModuleRegistryEntry> = {
  room_service: {
    configSchema: genericServiceConfigSchema,
    capabilities: GENERIC_SERVICE_CAPABILITIES,
    actions: ['addToOrder'],
  },
  restaurant: {
    configSchema: genericServiceConfigSchema,
    capabilities: [...GENERIC_SERVICE_CAPABILITIES, { id: 'allowsTableBooking', label: 'Permite reserva de mesa', default: true }],
    actions: ['addToOrder', 'bookTable'],
  },
  /// Fallback pros módulos de Hospitalidade sem regra própria ainda (Spa,
  /// Passeios, Eventos, Lavanderia, Kids Club, Piscinas, Academia,
  /// Transporte, Estacionamento) — mesmo schema genérico, sem capability
  /// específica de domínio até um deles precisar de verdade.
  generic_service: {
    configSchema: genericServiceConfigSchema,
    capabilities: GENERIC_SERVICE_CAPABILITIES,
    actions: ['addToOrder'],
  },
  digital_wallet: {
    configSchema: homeCardConfigSchema,
    capabilities: [],
    actions: ['viewStatement'],
  },
  loyalty: {
    configSchema: homeCardConfigSchema.extend({
      pointsPerCurrencyUnit: z.number().nonnegative().optional(),
    }),
    capabilities: [],
    actions: ['redeemPoints'],
  },
  promotions: {
    configSchema: homeCardConfigSchema,
    capabilities: [],
    actions: ['viewPromotion', 'redeemPromotion'],
  },
}

export function getModuleRegistryEntry(configSchemaId: string): ModuleRegistryEntry | undefined {
  return MODULE_REGISTRY[configSchemaId]
}

export type ModuleConfigurationValidation =
  | { success: true; data: Record<string, unknown> }
  | { success: false; error: 'unknown_module' | 'invalid_configuration' }

/// Fonte de verdade pra validar `Hotel.config.modules[id].configuration`
/// antes de persistir (usado a partir da Fase 3, no PATCH de hotel) — nunca
/// aceitar o objeto de configuração de um módulo sem passar por aqui.
export function validateModuleConfiguration(configSchemaId: string, configuration: unknown): ModuleConfigurationValidation {
  const entry = getModuleRegistryEntry(configSchemaId)
  if (!entry) return { success: false, error: 'unknown_module' }
  const parsed = entry.configSchema.safeParse(configuration)
  if (!parsed.success) return { success: false, error: 'invalid_configuration' }
  return { success: true, data: parsed.data as Record<string, unknown> }
}
