/**
 * Fonte única de verdade da identidade visual do portal. Substituiu o tema
 * escuro dourado/tinta herdado do Flutter (apps/konekto_portal/lib/theme/
 * konekto_brand.dart) pela identidade clara/rosa da marca Sevvn — a
 * mesma paleta de apps/konekto_site (#FF2E88 / #16181D / #F7F5F3 / #FAFAF9),
 * decisão do usuário pra ter uma marca consistente entre o site e o
 * produto (ver Fase de redesign pós-migração).
 *
 * Os NOMES dos tokens ficaram os mesmos de propósito (ink, gold, cream,
 * slate...) mesmo não descrevendo mais a cor literal — são só
 * identificadores, e centenas de componentes já usam essas classes
 * Tailwind (`text-cream`, `bg-gold`, `border-border-strong`...) pelo
 * PAPEL semântico (texto principal, destaque, borda), não pelo nome.
 * Trocar só os valores aqui evita teragregação em toda a árvore de
 * componentes.
 */
export const sevvnBrand = {
  /** Fundo de página (era o antigo "ink" escuro — agora vive em `page` pra não confundir com o papel de texto-sobre-destaque de `ink`). */
  page: '#FAFAF9',
  /** Texto sobre fundo de destaque (botões `bg-gold` sólidos) — precisa ser escuro, contraste bom sobre o rosa vívido. */
  ink: '#16181D',
  surface: '#FFFFFF',
  surfaceAlt: '#F7F5F3',
  border: 'rgba(22, 24, 29, 0.08)',
  borderStrong: 'rgba(22, 24, 29, 0.16)',
  /** Rosa vívido da marca — usado em botões sólidos, indicadores, decoração. */
  gold: '#FF2E88',
  /** Rosa mais escuro/saturado — usado em texto/links sobre fundo claro (contraste melhor que o rosa vívido em texto pequeno). */
  goldLight: '#B6005B',
  /** Texto principal — escuro sobre fundo claro. */
  cream: '#16181D',
  slate: '#5B5F68',
  slateSoft: '#85899A',
} as const

export type SevvnBrandColor = keyof typeof sevvnBrand
