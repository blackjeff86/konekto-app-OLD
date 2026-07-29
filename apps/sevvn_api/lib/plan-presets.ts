/// Plan Presets — camada entre o plano comercial (`HotelSubscription.plan`,
/// só rótulo de billing/relatório) e o Module Catalog. Um preset define o
/// conjunto padrão de módulos e templates visuais permitidos; o plano
/// comercial só aponta pra um preset (`HotelSubscription.presetId`).
///
/// Criar um plano comercial novo (ex: "Premium Plus", "Resort", "Signature")
/// não exige migration de schema nem mudar nenhuma camada acima desta —
/// basta uma entrada nova em `PLAN_PRESETS` e atribuir o `presetId` correto
/// aos hotéis que o contratarem (inclusive sob medida, fora do enum
/// `HotelPlan` de 3 valores usado hoje pro financeiro).
import { MODULE_CATALOG } from './module-catalog'

export type GuestTemplateId = 'aura' | 'bosque' | 'elite' | 'pulse' | 'horizon'

export interface PlanPreset {
  id: string
  name: string
  moduleIds: string[]
  templateIds: readonly GuestTemplateId[]
}

const CORE_MODULE_IDS = ['home', 'hotel_info', 'services', 'bookings', 'messages', 'profile', 'basic_notifications']

const ESSENTIAL_MODULE_IDS = [...CORE_MODULE_IDS, 'room_service', 'restaurant', 'tours', 'concierge']

const PREMIUM_EXTRA_MODULE_IDS = [
  'spa',
  'events',
  'laundry',
  'kids_club',
  'pools',
  'gym',
  'transport',
  'parking',
  'digital_checkin',
  'digital_checkout',
  'promotions',
  'loyalty',
  'digital_wallet',
  'interactive_map',
  'service_reviews',
  'multilingual_chat',
  'smart_notifications',
  'payments',
  'statements',
  'faq',
  'help_center',
]

const PREMIUM_MODULE_IDS = [...ESSENTIAL_MODULE_IDS, ...PREMIUM_EXTRA_MODULE_IDS]

/// Enterprise recebe o catálogo inteiro automaticamente — módulo novo
/// cadastrado em `module-catalog.ts` já entra pra Enterprise sem editar
/// este arquivo de novo (mesmo princípio que `defaultFeaturesByPlan` já
/// usava pro Enterprise antes desta migração).
const ENTERPRISE_MODULE_IDS = MODULE_CATALOG.map((module) => module.id)

export const PLAN_PRESETS: PlanPreset[] = [
  { id: 'essential', name: 'Essential', moduleIds: ESSENTIAL_MODULE_IDS, templateIds: ['aura', 'bosque'] },
  { id: 'premium', name: 'Premium', moduleIds: PREMIUM_MODULE_IDS, templateIds: ['aura', 'bosque', 'elite', 'pulse', 'horizon'] },
  { id: 'enterprise', name: 'Enterprise', moduleIds: ENTERPRISE_MODULE_IDS, templateIds: ['aura', 'bosque', 'elite', 'pulse', 'horizon'] },
]

export function getPlanPreset(presetId: string): PlanPreset {
  return PLAN_PRESETS.find((preset) => preset.id === presetId) ?? PLAN_PRESETS[0]
}

export function isPlanPresetId(value: string): boolean {
  return PLAN_PRESETS.some((preset) => preset.id === value)
}
