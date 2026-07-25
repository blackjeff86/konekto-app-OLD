import type { HotelPlan } from '@/app/generated/prisma/client'

/// As 9 flags exclusivas de Premium/Enterprise (ver "FUNCIONALIDADES
/// EXCLUSIVAS DOS PLANOS PREMIUM E ENTERPRISE" na spec do White Label).
/// Tudo que NÃO está nesta lista (auth, integrações PMS/CRS/ERP/Channel
/// Manager, home, serviços, mensagens com recepção, minhas reservas,
/// perfil, configurações, notificações básicas) é núcleo da plataforma —
/// sempre disponível, em qualquer plano, sem flag nenhuma.
export const FEATURE_FLAGS = [
  'digital_checkin',
  'digital_checkout',
  'interactive_map',
  'promotions',
  'loyalty',
  'digital_wallet',
  'multilingual_chat',
  'service_reviews',
  'smart_notifications',
] as const

export type FeatureFlag = (typeof FEATURE_FLAGS)[number]

export function isFeatureFlag(value: string): value is FeatureFlag {
  return (FEATURE_FLAGS as readonly string[]).includes(value)
}

/// Templates do app do hóspede disponíveis por plano. Essential ⊂ Premium
/// ⊂ Enterprise — plano mais alto sempre pode escolher qualquer template
/// de um plano mais baixo (nunca o contrário).
const ESSENTIAL_TEMPLATES = ['aura', 'bosque'] as const
const PREMIUM_TEMPLATES = ['aura', 'bosque', 'elite', 'pulse', 'horizon'] as const

export type GuestTemplateId = (typeof PREMIUM_TEMPLATES)[number]

export function templatesOfPlan(plan: HotelPlan): readonly GuestTemplateId[] {
  switch (plan) {
    case 'essential':
      return ESSENTIAL_TEMPLATES
    case 'premium':
    case 'enterprise':
      return PREMIUM_TEMPLATES
  }
}

/// Default de flags por plano. Enterprise sempre retorna o catálogo
/// completo (equivalente ao `"*"` da spec) em vez de uma lista fixa
/// duplicada — uma flag nova adicionada em `FEATURE_FLAGS` já entra pra
/// Enterprise automaticamente, sem precisar editar este arquivo de novo.
export function defaultFeaturesByPlan(plan: HotelPlan): FeatureFlag[] {
  switch (plan) {
    case 'essential':
      return []
    case 'premium':
    case 'enterprise':
      return [...FEATURE_FLAGS]
  }
}

/// Fonte de verdade de "esse hotel tem acesso a essa feature?" — nunca
/// checar `plan` direto em nenhuma tela/rota, sempre passar por aqui.
/// `extraFeatures` (vindo de `Hotel.config.enabledFeatures`) só ADICIONA
/// flags além do default do plano (cortesia liberada pela equipe Konekto
/// via konekto_admin) — nunca remove uma flag que o plano já dá de graça,
/// o que mantém a regra "plano mais alto sempre pode tudo que um mais
/// baixo pode" simples de garantir (não existe "desligar" uma flag do
/// plano). Ignora silenciosamente qualquer string em `extraFeatures` que
/// não seja uma flag conhecida (dado antigo/erro de digitação não deve
/// derrubar a resolução das outras).
export function resolveEnabledFeatures(plan: HotelPlan, extraFeatures: string[] = []): FeatureFlag[] {
  const defaults = defaultFeaturesByPlan(plan)
  const extras = extraFeatures.filter(isFeatureFlag)
  return [...new Set([...defaults, ...extras])]
}
