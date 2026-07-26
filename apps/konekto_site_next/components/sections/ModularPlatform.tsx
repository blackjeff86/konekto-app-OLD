import { Section } from "@/components/ui/Section";
import { SectionHeading } from "@/components/ui/SectionHeading";

interface Feature {
  title: string;
  description: string;
  icon: React.ReactNode;
}

const FEATURES: Feature[] = [
  {
    title: "Templates",
    description:
      "Definem só a identidade visual: layout, tipografia, animações. Trocar de template não altera nenhuma configuração.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF2E88" strokeWidth="2">
        <rect x="3" y="3" width="7" height="18" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </svg>
    ),
  },
  {
    title: "Módulos",
    description:
      "Definem as capacidades do app. Ative só o que faz sentido pra sua operação, e ative mais depois, sem reconstruir nada.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF2E88" strokeWidth="2">
        <rect x="3" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="3" y="14" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </svg>
    ),
  },
  {
    title: "Personalização",
    description:
      "Marca, cores, catálogo e conteúdo do seu hotel, sempre 100% White Label, sem menção à Sevvn para o hóspede.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF2E88" strokeWidth="2">
        <path d="M12 3v18M3 12h18" />
      </svg>
    ),
  },
];

export function ModularPlatform() {
  return (
    <Section id="plataforma">
      <SectionHeading
        eyebrow="Plataforma modular"
        title="Um só produto. Uma flexibilidade enorme."
        lede="O template escolhido, os módulos habilitados e o nível de personalização são o que tornam cada aplicativo único, sobre uma arquitetura sólida e extremamente flexível."
        maxWidth="680px"
        marginBottom="56px"
      />
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-3">
        {FEATURES.map((feature) => (
          <div key={feature.title} className="rounded-2xl bg-card p-7">
            <div className="flex h-10 w-10 items-center justify-center rounded-[10px] bg-primary-soft">
              {feature.icon}
            </div>
            <h3 className="mt-4 text-[16px] font-bold text-ink">{feature.title}</h3>
            <p className="mt-[6px] text-[13.5px] leading-[1.6] text-muted">{feature.description}</p>
          </div>
        ))}
      </div>
    </Section>
  );
}
