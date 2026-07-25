/// Catálogo central de módulos — descreve TODO módulo que a plataforma pode
/// oferecer ao hóspede (implementado ou não). Isto é o "Module Catalog" da
/// arquitetura em camadas (ver tasks/plan.md / docs do módulo). O Catalog só
/// DESCREVE — quem implementa de fato é o Module Registry
/// (`lib/module-registry.ts`), quem decide o que fica ligado por hotel é o
/// Module Engine (`lib/module-engine.ts`), e quem decide disponibilidade por
/// plano comercial é o Plan Preset (`lib/plan-presets.ts`).
///
/// Servido via `GET /api/modules-catalog` — portal, konekto_admin e o app do
/// hóspede consultam este endpoint em runtime. Nenhum dos 3 mantém cópia
/// local da lista (diferente do antigo `feature-flags.ts`, que era
/// replicado à mão em 3 lugares — ver nota histórica no fim deste arquivo).
///
/// ## Adicionar um módulo novo
/// 1. Aqui: uma entrada em `MODULE_CATALOG` (`implemented: false` até ter
///    Widget/Screen de verdade registrados).
/// 2. `lib/module-registry.ts`: `configSchema` (Zod) + capabilities/actions,
///    quando o módulo passar a ser implementado.
/// 3. `apps/konekto_mobile/lib/modules/module_registry.dart`: Widget/Screen
///    de verdade.
/// Nenhum template, Module Engine ou camada de Home/Navigation/Theme muda.
export type ModuleCategory = 'core' | 'hospitalidade' | 'financeiro' | 'experiencia' | 'comunicacao'

export type ModulePlacement = 'home' | 'bottomNav' | 'servicesMenu' | 'settings'

export interface ModuleDefinition {
  id: string
  name: string
  description: string
  category: ModuleCategory
  /** Só módulos de `category: 'hospitalidade'` — agrupamento na tela de
   *  Serviços (ver `SERVICE_GROUPS` abaixo). */
  groupId?: string
  /** Nome de ícone Material — mesma convenção que `Service.icon` já usa. */
  icon: string
  placement: ModulePlacement[]
  /** Identificador LÓGICO de tela — nunca uma rota. Quem decide como
   *  apresentar (página/modal/bottom sheet/...) é o Navigation Engine. */
  screenId?: string
  defaultOrder: number
  dependencies: string[]
  /** false = catálogo existe, mas não tem Widget/Screen registrados ainda
   *  (não aparece como opção de verdade em nenhuma UI de hotel/admin). */
  implemented: boolean
  /** Aponta pro schema de configuração deste módulo no Module Registry —
   *  o Catalog não conhece o shape, só a existência. */
  configSchemaId?: string
}

export interface ServiceGroup {
  id: string
  name: string
  defaultOrder: number
}

/// Agrupamento da tela de Serviços — catálogo pequeno, fixo nesta entrega
/// (não é um construtor de grupo customizado por hotel; extensível depois
/// sem replanejar nada disso).
export const SERVICE_GROUPS: ServiceGroup[] = [
  { id: 'gastronomia', name: 'Gastronomia', defaultOrder: 0 },
  { id: 'bem_estar', name: 'Bem-estar', defaultOrder: 1 },
  { id: 'mobilidade', name: 'Mobilidade', defaultOrder: 2 },
  { id: 'experiencias', name: 'Experiências', defaultOrder: 3 },
]

export const MODULE_CATALOG: ModuleDefinition[] = [
  // ── core — sempre permitido em qualquer plano; hotel pode desligar individualmente ──
  { id: 'home', name: 'Home', description: 'Tela inicial do app do hóspede.', category: 'core', icon: 'home', placement: ['bottomNav'], screenId: 'home', defaultOrder: 0, dependencies: [], implemented: true },
  { id: 'hotel_info', name: 'Informações da hospedagem', description: 'Wi-Fi, número do quarto, dados da estadia.', category: 'core', icon: 'info', placement: ['home'], screenId: 'hotel_info', defaultOrder: 1, dependencies: [], implemented: true },
  { id: 'services', name: 'Serviços', description: 'Agregador dos módulos de Hospitalidade habilitados.', category: 'core', icon: 'grid_view', placement: ['bottomNav', 'home'], screenId: 'services', defaultOrder: 2, dependencies: [], implemented: true },
  { id: 'bookings', name: 'Reservas', description: 'Pedidos e reservas do hóspede.', category: 'core', icon: 'event_note', placement: ['bottomNav'], screenId: 'bookings', defaultOrder: 3, dependencies: [], implemented: true },
  { id: 'messages', name: 'Mensagens', description: 'Chat com a recepção do hotel.', category: 'core', icon: 'chat_bubble_outline', placement: ['bottomNav', 'home'], screenId: 'messages', defaultOrder: 4, dependencies: [], implemented: true },
  { id: 'profile', name: 'Perfil', description: 'Dados do hóspede e conta da estadia.', category: 'core', icon: 'person_outline', placement: ['bottomNav'], screenId: 'profile', defaultOrder: 5, dependencies: [], implemented: true },
  { id: 'basic_notifications', name: 'Notificações Básicas', description: 'Avisos da recepção e status de pedidos.', category: 'core', icon: 'notifications_none', placement: ['home'], screenId: 'notices', defaultOrder: 6, dependencies: [], implemented: true },

  // ── hospitalidade — mapeiam pro catálogo `Service` (gating real na Fase 12) ──
  { id: 'room_service', name: 'Room Service', description: 'Pedidos de quarto.', category: 'hospitalidade', groupId: 'gastronomia', icon: 'room_service', placement: ['servicesMenu'], screenId: 'service_room_service', defaultOrder: 0, dependencies: ['services'], implemented: true, configSchemaId: 'room_service' },
  { id: 'restaurant', name: 'Restaurantes', description: 'Cardápio e reservas de mesa dos restaurantes do hotel.', category: 'hospitalidade', groupId: 'gastronomia', icon: 'restaurant', placement: ['servicesMenu'], screenId: 'service_restaurant', defaultOrder: 1, dependencies: ['services'], implemented: true, configSchemaId: 'restaurant' },
  { id: 'spa', name: 'Spa', description: 'Tratamentos e agendamento de spa.', category: 'hospitalidade', groupId: 'bem_estar', icon: 'spa', placement: ['servicesMenu'], screenId: 'service_spa', defaultOrder: 2, dependencies: ['services'], implemented: true, configSchemaId: 'generic_service' },
  { id: 'tours', name: 'Passeios', description: 'Passeios e atividades oferecidas pelo hotel.', category: 'hospitalidade', groupId: 'experiencias', icon: 'directions_walk', placement: ['servicesMenu'], screenId: 'service_tours', defaultOrder: 3, dependencies: ['services'], implemented: true, configSchemaId: 'generic_service' },
  { id: 'events', name: 'Eventos', description: 'Eventos e programação do hotel.', category: 'hospitalidade', groupId: 'experiencias', icon: 'event', placement: ['servicesMenu'], screenId: 'service_events', defaultOrder: 4, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },
  { id: 'concierge', name: 'Concierge', description: 'Atendimento personalizado de concierge.', category: 'hospitalidade', groupId: 'experiencias', icon: 'support_agent', placement: ['servicesMenu'], screenId: 'service_concierge', defaultOrder: 5, dependencies: ['services'], implemented: false },
  { id: 'laundry', name: 'Lavanderia', description: 'Serviço de lavanderia.', category: 'hospitalidade', groupId: 'gastronomia', icon: 'local_laundry_service', placement: ['servicesMenu'], screenId: 'service_laundry', defaultOrder: 6, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },
  { id: 'kids_club', name: 'Kids Club', description: 'Atividades infantis.', category: 'hospitalidade', groupId: 'bem_estar', icon: 'child_care', placement: ['servicesMenu'], screenId: 'service_kids_club', defaultOrder: 7, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },
  { id: 'pools', name: 'Piscinas', description: 'Horários e reserva de espreguiçadeiras.', category: 'hospitalidade', groupId: 'bem_estar', icon: 'pool', placement: ['servicesMenu'], screenId: 'service_pools', defaultOrder: 8, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },
  { id: 'gym', name: 'Academia', description: 'Horários e informações da academia.', category: 'hospitalidade', groupId: 'bem_estar', icon: 'fitness_center', placement: ['servicesMenu'], screenId: 'service_gym', defaultOrder: 9, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },
  { id: 'transport', name: 'Transporte', description: 'Transfer e transporte do hotel.', category: 'hospitalidade', groupId: 'mobilidade', icon: 'directions_car', placement: ['servicesMenu'], screenId: 'service_transport', defaultOrder: 10, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },
  { id: 'parking', name: 'Estacionamento', description: 'Informações e reserva de vaga de estacionamento.', category: 'hospitalidade', groupId: 'mobilidade', icon: 'local_parking', placement: ['servicesMenu'], screenId: 'service_parking', defaultOrder: 11, dependencies: ['services'], implemented: false, configSchemaId: 'generic_service' },

  // ── financeiro ──
  { id: 'digital_wallet', name: 'Carteira Digital', description: 'Saldo e extrato de consumo do hóspede.', category: 'financeiro', icon: 'account_balance_wallet', placement: ['home', 'bottomNav'], screenId: 'wallet', defaultOrder: 0, dependencies: [], implemented: true, configSchemaId: 'digital_wallet' },
  { id: 'payments', name: 'Pagamentos', description: 'Pagamento de consumo direto pelo app.', category: 'financeiro', icon: 'payment', placement: ['home'], screenId: 'payments', defaultOrder: 1, dependencies: ['digital_wallet'], implemented: false },
  { id: 'statements', name: 'Extratos', description: 'Extrato detalhado de consumo por período.', category: 'financeiro', icon: 'receipt_long', placement: ['home'], screenId: 'statements', defaultOrder: 2, dependencies: ['digital_wallet'], implemented: false },

  // ── experiência ──
  { id: 'promotions', name: 'Promoções', description: 'Cupons e promoções aplicáveis a pedidos.', category: 'experiencia', icon: 'local_offer', placement: ['home'], screenId: 'promotions', defaultOrder: 0, dependencies: [], implemented: true, configSchemaId: 'promotions' },
  { id: 'loyalty', name: 'Programa de Fidelidade', description: 'Pontos e benefícios de fidelidade.', category: 'experiencia', icon: 'stars', placement: ['home', 'bottomNav'], screenId: 'loyalty', defaultOrder: 1, dependencies: [], implemented: true, configSchemaId: 'loyalty' },
  { id: 'interactive_map', name: 'Mapa Interativo', description: 'Mapa do hotel e instalações.', category: 'experiencia', icon: 'map', placement: ['home'], screenId: 'interactive_map', defaultOrder: 2, dependencies: [], implemented: false },
  { id: 'service_reviews', name: 'Avaliações', description: 'Avaliação de serviços pelo hóspede.', category: 'experiencia', icon: 'star_rate', placement: ['home'], screenId: 'reviews', defaultOrder: 3, dependencies: [], implemented: false },
  { id: 'digital_checkin', name: 'Check-in Digital', description: 'Check-in antecipado pelo app.', category: 'experiencia', icon: 'login', placement: ['home'], screenId: 'digital_checkin', defaultOrder: 4, dependencies: [], implemented: false },
  { id: 'digital_checkout', name: 'Check-out Digital', description: 'Check-out pelo app.', category: 'experiencia', icon: 'logout', placement: ['home'], screenId: 'digital_checkout', defaultOrder: 5, dependencies: [], implemented: false },
  { id: 'smart_notifications', name: 'Notificações Inteligentes', description: 'Notificações contextuais (ex: horário de check-out, promoções ativas).', category: 'experiencia', icon: 'notifications_active', placement: ['settings'], defaultOrder: 6, dependencies: ['basic_notifications'], implemented: false },

  // ── comunicação ──
  { id: 'multilingual_chat', name: 'Chat Multilíngue', description: 'Tradução automática do chat com a recepção.', category: 'comunicacao', icon: 'translate', placement: ['settings'], defaultOrder: 0, dependencies: ['messages'], implemented: false },
  { id: 'faq', name: 'FAQ', description: 'Perguntas frequentes do hotel.', category: 'comunicacao', icon: 'help_outline', placement: ['home'], screenId: 'faq', defaultOrder: 1, dependencies: [], implemented: false },
  { id: 'help_center', name: 'Central de Ajuda', description: 'Central de ajuda e suporte do app.', category: 'comunicacao', icon: 'support', placement: ['settings'], screenId: 'help_center', defaultOrder: 2, dependencies: [], implemented: false },
]

export function isModuleId(value: string): boolean {
  return MODULE_CATALOG.some((module) => module.id === value)
}

export function getModuleDefinition(id: string): ModuleDefinition | undefined {
  return MODULE_CATALOG.find((module) => module.id === id)
}

/// Nota histórica: até esta migração, plano/template/feature flag viviam
/// todos em `lib/feature-flags.ts` (apagado na Fase 3 desta migração), com
/// FEATURE_FLAGS espelhado à mão em `konekto_admin`. Este catálogo substitui
/// aquele — ver `tasks/plan.md` na raiz do repo pro plano de migração completo.
