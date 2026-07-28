export interface Plan {
  id: string
  name: string
  audience: string
  price: string
  priceSuffix?: string
  founderNote?: string
  tagline: string
  ctaLabel: string
  ctaHref: string
  featured?: boolean
  highlights: string[]
}

export const PLANS: Plan[] = [
  {
    id: "essential",
    name: "Essential",
    audience: "Pousadas, hotéis independentes e pequenos hotéis",
    price: "R$ 1.790",
    priceSuffix: "/mês",
    founderNote: "Condição especial de lançamento · valor futuro previsto de R$ 2.490/mês",
    tagline: "Tudo o que sua operação precisa para começar uma experiência digital conectada.",
    ctaLabel: "Quero conhecer",
    ctaHref: "/contato#hotel-demo",
    highlights: [
      "Templates Aura e Bosque",
      "Módulos essenciais da jornada",
      "Base White Label da plataforma",
      "Operação inicial conectada",
    ],
  },
  {
    id: "premium",
    name: "Premium",
    audience: "Hotéis, hotéis boutique, resorts e operações com maior complexidade",
    price: "R$ 4.490",
    priceSuffix: "/mês",
    tagline: "Mais automação, personalização e recursos para ampliar toda a jornada do hóspede.",
    ctaLabel: "Agendar demonstração",
    ctaHref: "/contato#hotel-demo",
    featured: true,
    highlights: [
      "Todos os cinco templates",
      "Expansão de módulos avançados",
      "Mais integrações e personalização",
      "Estrutura pronta para crescimento",
    ],
  },
  {
    id: "enterprise",
    name: "Enterprise",
    audience: "Redes, resorts, grupos, grandes operações e multiunidade",
    price: "Sob consulta",
    tagline:
      "Arquitetura personalizada, integrações específicas, governança, SLA, multiunidade e desenvolvimento sob demanda.",
    ctaLabel: "Falar com o time",
    ctaHref: "/contato#enterprise",
    highlights: [
      "Arquitetura personalizada",
      "Módulos exclusivos",
      "Ambiente dedicado e SLA",
      "Gestor técnico e multiunidade",
    ],
  },
]
