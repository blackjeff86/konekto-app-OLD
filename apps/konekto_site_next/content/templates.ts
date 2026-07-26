export type GuestTemplateId = "aura" | "bosque" | "elite" | "pulse" | "horizon";

/**
 * Os 5 templates visuais reais — nome, tagline, descrição, cor de destaque e
 * screenshot copiados 1:1 de `konekto_portal_next/app/(portal)/settings/
 * appearance/page.tsx` (`TEMPLATE_OPTIONS`). Fonte de verdade de cor/
 * tipografia continua sendo `apps/konekto_mobile/lib/templates/<id>/theme.dart`.
 */
export interface TemplateOption {
  id: GuestTemplateId;
  name: string;
  tagline: "ESSENTIAL" | "PREMIUM";
  description: string;
  accent: string;
  previewImage: string;
}

export const TEMPLATES: TemplateOption[] = [
  {
    id: "aura",
    name: "Aura",
    tagline: "ESSENTIAL",
    description:
      "Minimalismo sofisticado — roxo suave, Libre Caslon Text e Work Sans.",
    accent: "#4F378A",
    previewImage: "/appearance/aura-home.png",
  },
  {
    id: "bosque",
    name: "Bosque",
    tagline: "ESSENTIAL",
    description:
      "Design biofílico — verde-floresta orgânico, Literata e Plus Jakarta Sans.",
    accent: "#173124",
    previewImage: "/appearance/bosque-home.png",
  },
  {
    id: "elite",
    name: "Elite",
    tagline: "PREMIUM",
    description:
      "Luxo discreto — preto e dourado sóbrio sobre creme, Playfair Display.",
    accent: "#775A19",
    previewImage: "/appearance/elite-home.png",
  },
  {
    id: "pulse",
    name: "Pulse",
    tagline: "PREMIUM",
    description:
      "Glassmorphism tech-luxo — fundo escuro, dourado vibrante, Montserrat.",
    accent: "#D4AF37",
    previewImage: "/appearance/pulse-home.png",
  },
  {
    id: "horizon",
    name: "Horizon",
    tagline: "PREMIUM",
    description: "Resort costeiro — azul-oceano e laranja-pôr-do-sol, Playfair Display.",
    accent: "#005D90",
    previewImage: "/appearance/horizon-home.png",
  },
];

export function getTemplate(id: GuestTemplateId): TemplateOption {
  const template = TEMPLATES.find((t) => t.id === id);
  if (!template) throw new Error(`Template desconhecido: ${id}`);
  return template;
}
