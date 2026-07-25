/**
 * Seções do PortalSidebar — portado dos consts `_kXxxSection` de
 * apps/konekto_portal/lib/features/dashboard/dashboard_page.dart. Cada
 * seção agora é uma rota real (ver plano de migração) em vez de um índice
 * de estado local.
 */
export type PortalBadgeKey = 'pendingOrderCount' | 'unreadMessagesCount' | 'unreadSupportCount'

export interface PortalNavSection {
  icon: string
  title: string
  description: string
  href: string
  /** Prefixo de rota usado pra decidir o estado "ativo" — cobre sub-rotas como /settings/*. */
  matchPrefix: string
  badgeKey?: PortalBadgeKey
  gerenteOnly?: boolean
}

export const PORTAL_NAV_SECTIONS: PortalNavSection[] = [
  {
    icon: '📊',
    title: 'Visão Geral',
    description: 'Ocupação, receita e o que está movimentando o hotel.',
    href: '/dashboard',
    matchPrefix: '/dashboard',
  },
  {
    icon: '🧑‍🤝‍🧑',
    title: 'Hóspedes',
    description: 'Conceda e revogue acesso, veja quem está hospedado.',
    href: '/guests',
    matchPrefix: '/guests',
  },
  {
    icon: '👥',
    title: 'Clientes',
    description: 'Histórico completo de quem já se hospedou e quanto gastou.',
    href: '/customers',
    matchPrefix: '/customers',
  },
  {
    icon: '🚪',
    title: 'Quartos',
    description: 'Estadias com vários hóspedes, avisos e fechamento de conta.',
    href: '/rooms',
    matchPrefix: '/rooms',
    badgeKey: 'unreadMessagesCount',
  },
  {
    icon: '🧾',
    title: 'Pedidos',
    description: 'Acompanhe pedidos de room service, spa e restaurante.',
    href: '/orders',
    matchPrefix: '/orders',
    badgeKey: 'pendingOrderCount',
  },
  {
    icon: '🎧',
    title: 'Suporte',
    description: 'Fale direto com a equipe do Konekto.',
    href: '/support',
    matchPrefix: '/support',
    badgeKey: 'unreadSupportCount',
  },
  {
    icon: '⚙️',
    title: 'Configurações',
    description: 'Marca, cores, serviços e cardápio do seu hotel.',
    href: '/settings/branding',
    matchPrefix: '/settings',
    gerenteOnly: true,
  },
]
