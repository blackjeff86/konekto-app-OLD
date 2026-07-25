import type { HotelPlan } from '@/app/generated/prisma/client'

/// Catálogo central do White Label — plano comercial, templates do app do
/// hóspede e feature flags. Fonte de verdade pros 3, mas NENHUM dos dois
/// catálogos abaixo é uma tabela no banco — são listas fixas em código,
/// cada uma com uma segunda cópia em outro app que precisa ficar em sync
/// manualmente (documentado abaixo de cada uma).
///
/// ## Adicionar um 6º template
/// 1. Aqui: acrescentar o id em `PREMIUM_TEMPLATES` (e em `ESSENTIAL_TEMPLATES`
///    também, se o novo template também for Essential).
/// 2. `apps/konekto_portal_next/app/(portal)/settings/appearance/page.tsx`:
///    acrescentar uma entrada em `TEMPLATE_OPTIONS` (nome, tagline,
///    descrição, cor, print em `public/appearance/<id>-home.png`).
/// 3. `apps/konekto_mobile/lib/templates/<id>/`: criar `theme.dart`
///    (`GuestTemplateTheme`) + `home_screen.dart` no mínimo (ver os 5
///    existentes como referência — Room Service/Chat/Onboarding/Diretório/
///    Loyalty/Wallet são opcionais, com dado de demonstração até serem
///    ligados a dado real).
/// 4. `apps/konekto_mobile/lib/templates/guest_template_registry.dart`:
///    acrescentar o `GuestTemplateId`, `guestTemplateThemes` e
///    `_homeContentBuilders`.
///
/// ## Adicionar uma 10ª feature flag
/// Só precisa de 2 lugares:
/// 1. Aqui: acrescentar o id em `FEATURE_FLAGS` — `defaultFeaturesByPlan`/
///    `resolveEnabledFeatures`/`isFeatureFlag` já pegam a flag nova
///    automaticamente, nada mais muda neste arquivo.
/// 2. `apps/konekto_admin/lib/features/clients/client_detail_page.dart`:
///    acrescentar `(id, 'Rótulo em PT-BR')` em `_kFeatureFlags` (senão a
///    flag existe no backend mas não aparece pra equipe Konekto liberar
///    como cortesia).
/// Se a feature precisar de UI de verdade no app do hóspede, o padrão é
/// `GuestFeatureGate` (`lib/templates/shared/widgets/guest_feature_gate.dart`)
/// — ver `lib/templates/{elite,pulse,horizon}/{loyalty,wallet}_screen.dart`
/// pra um exemplo de tela inteira atrás de uma flag.
///
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
