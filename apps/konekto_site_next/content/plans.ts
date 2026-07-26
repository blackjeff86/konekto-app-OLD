/**
 * Copy e preço dos planos comerciais — dado do briefing de reposicionamento,
 * não do backend (é texto de marketing).
 *
 * Desconto de Cliente Fundador é o mesmo percentual (~28%) em Essential e
 * Premium: 1.790/2.490 = 3.230/4.490 ≈ 71,9% do valor futuro.
 */
export interface Plan {
  id: string;
  name: string;
  audience: string;
  price: string;
  priceSuffix?: string;
  founderNote?: string;
  tagline: string;
  ctaLabel: string;
  ctaHref: string;
  featured?: boolean;
}

export const PLANS: Plan[] = [
  {
    id: "essential",
    name: "Essential",
    audience: "Pousadas, hotéis independentes e pequenos hotéis",
    price: "R$ 1.790",
    priceSuffix: "/mês",
    founderNote: "Cliente Fundador · valor futuro de R$ 2.490/mês",
    tagline: "Tudo o que seu hotel precisa para iniciar sua transformação digital.",
    ctaLabel: "Começar",
    ctaHref: "mailto:contato@konekto.app",
  },
  {
    id: "premium",
    name: "Premium",
    audience: "Mais personalização, automação e experiência",
    price: "R$ 3.230",
    priceSuffix: "/mês",
    founderNote: "Cliente Fundador · valor futuro de R$ 4.490/mês",
    tagline: "Mais personalização. Mais automação. Mais experiência para seus hóspedes.",
    ctaLabel: "Começar",
    ctaHref: "mailto:contato@konekto.app",
    featured: true,
  },
  {
    id: "enterprise",
    name: "Enterprise",
    audience: "Arquitetura personalizada para grandes operações",
    price: "Sob consulta",
    tagline:
      "Desenvolvimento dedicado, módulos exclusivos, integrações específicas, ambiente dedicado, SLA premium, gestor técnico, multiunidade e governança.",
    ctaLabel: "Falar com o time",
    ctaHref: "mailto:contato@konekto.app",
  },
];
