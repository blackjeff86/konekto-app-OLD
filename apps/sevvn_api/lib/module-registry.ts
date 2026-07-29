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

const restaurantConfigSchema = genericServiceConfigSchema.extend({
  /// Como o hóspede interage com a reserva:
  /// - `party_size_only`: informa só "mesa para quantas pessoas" e a Sevvn
  ///   escolhe a melhor mesa/tipo disponível por trás.
  /// - `table_type_selection`: o hóspede escolhe explicitamente o tipo de
  ///   mesa dentre as disponíveis.
  /// - `hybrid`: mostra lotação por pessoas e também permite seleção do tipo
  ///   de mesa quando o hotel quiser expor esse nível de detalhe.
  bookingMode: z.enum(['party_size_only', 'table_type_selection', 'hybrid']).optional(),
  /// Mostrar ou não o cardápio dentro do app do hóspede.
  showMenuInGuestApp: z.boolean().optional(),
  /// Mostrar os preços dos pratos quando o cardápio estiver visível.
  showMenuPrices: z.boolean().optional(),
  /// Tamanho máximo de grupo que o hóspede pode informar na UI de reserva.
  maxPartySize: z.number().int().min(1).max(40).optional(),
  /// Fonte operacional do inventário de mesas.
  tableInventorySource: z.enum(['sevvn', 'external', 'hybrid']).optional(),
  /// Permite fila de espera quando não houver mesa disponível.
  waitlistEnabled: z.boolean().optional(),
  /// Quantas entradas de fila de espera o restaurante aceita por turno.
  waitlistCapacity: z.number().int().min(0).max(500).optional(),
  /// Em quantos minutos a reserva expira caso o hóspede não chegue/confirme.
  reservationExpiryMinutes: z.number().int().min(1).max(240).optional(),
})

const roomServiceConfigSchema = genericServiceConfigSchema.extend({
  /// Mostrar ou não a seção de frigobar/minibar no app do hóspede.
  showMinibarInGuestApp: z.boolean().optional(),
  /// Permite ao próprio hóspede informar consumo de frigobar pelo app.
  allowGuestConsumptionReports: z.boolean().optional(),
  /// Permite à recepção lançar consumo manualmente em nome do hóspede.
  allowStaffConsumptionLaunch: z.boolean().optional(),
  /// Fonte operacional do fulfillment de room service.
  fulfillmentMode: z.enum(['sevvn', 'external', 'hybrid']).optional(),
})

const conciergeConfigSchema = genericServiceConfigSchema.extend({
  requestCategories: z.array(z.string().trim().min(1).max(60)).max(20).optional(),
  responseSlaMinutes: z.number().int().min(1).max(1440).optional(),
  showEstimatedResponseTime: z.boolean().optional(),
  allowFileAttachments: z.boolean().optional(),
  escalationMode: z.enum(['manual', 'automatic', 'hybrid']).optional(),
})

const homeCardConfigSchema = z.object({
  showOnHome: z.boolean().optional(),
  order: z.number().int().optional(),
})

export const MODULE_REGISTRY: Record<string, ModuleRegistryEntry> = {
  room_service: {
    configSchema: roomServiceConfigSchema,
    capabilities: [
      ...GENERIC_SERVICE_CAPABILITIES,
      { id: 'supportsMinibar', label: 'Suporta frigobar/minibar', default: true },
      { id: 'allowsGuestConsumptionReport', label: 'Permite hóspede informar consumo', default: true },
      { id: 'allowsStaffConsumptionLaunch', label: 'Permite recepção lançar consumo', default: true },
    ],
    actions: ['addToOrder', 'reportConsumption'],
  },
  restaurant: {
    configSchema: restaurantConfigSchema,
    capabilities: [
      ...GENERIC_SERVICE_CAPABILITIES,
      { id: 'allowsTableBooking', label: 'Permite reserva de mesa', default: true },
      { id: 'showsMenu', label: 'Exibe cardápio no app do hóspede', default: true },
      { id: 'showsMenuPrices', label: 'Exibe preços dos pratos', default: true },
      { id: 'collectsPartySize', label: 'Pergunta mesa para quantas pessoas', default: true },
      { id: 'supportsWaitlist', label: 'Permite fila de espera', default: false },
      { id: 'hasReservationExpiryWindow', label: 'Reserva expira após um limite de tempo', default: true },
    ],
    actions: ['addToOrder', 'bookTable'],
  },
  concierge: {
    configSchema: conciergeConfigSchema,
    capabilities: [
      ...GENERIC_SERVICE_CAPABILITIES,
      { id: 'allowsDirectChat', label: 'Permite conversa direta com a equipe', default: true },
      { id: 'showsRequestCategories', label: 'Exibe categorias de atendimento ao hóspede', default: true },
      { id: 'showsResponseSla', label: 'Exibe tempo estimado de resposta', default: true },
    ],
    actions: ['sendMessage', 'createRequest'],
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
  basic_notifications: {
    configSchema: homeCardConfigSchema.extend({
      channels: z
        .object({
          inApp: z.boolean().optional(),
          browser: z.boolean().optional(),
          email: z.boolean().optional(),
          whatsapp: z.boolean().optional(),
        })
        .optional(),
      domainPolicies: z
        .object({
          roomServiceOrders: z
            .object({
              notifyOnAccepted: z.boolean().optional(),
              notifyOnCompleted: z.boolean().optional(),
              notifyOnCancelled: z.boolean().optional(),
              notifyOnStaffConsumptionRecorded: z.boolean().optional(),
            })
            .optional(),
          restaurantReservations: z
            .object({
              notifyOnConfirmed: z.boolean().optional(),
              notifyOnCancelled: z.boolean().optional(),
              notifyOnRescheduled: z.boolean().optional(),
              notifyBeforeExpiry: z.boolean().optional(),
              expiryWarningMinutes: z.number().int().min(1).max(240).optional(),
            })
            .optional(),
        })
        .optional(),
    }),
    capabilities: [
      { id: 'supportsOperationalAlerts', label: 'Suporta alertas operacionais', default: true },
      { id: 'supportsReservationLifecycleAlerts', label: 'Notifica ciclo de vida da reserva', default: true },
    ],
    actions: ['sendOperationalNotification'],
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
