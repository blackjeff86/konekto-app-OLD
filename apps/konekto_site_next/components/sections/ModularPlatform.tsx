import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"

interface Feature {
  title: string
  description: string
  icon: React.ReactNode
}

const FEATURES: Feature[] = [
  {
    title: "Plano",
    description:
      "Define o ponto de partida comercial da operação e o espaço de evolução dentro da plataforma.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF2E88" strokeWidth="2">
        <rect x="3" y="3" width="7" height="18" rx="1.5" />
        <rect x="14" y="3" width="7" height="7" rx="1.5" />
        <rect x="14" y="14" width="7" height="7" rx="1.5" />
      </svg>
    ),
  },
  {
    title: "Template",
    description:
      "Define a identidade visual da experiência. A lógica continua sendo a mesma plataforma, não um produto diferente.",
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
    title: "Módulos",
    description:
      "Define as capacidades da operação. Cada hotel ativa e configura apenas o que faz sentido para sua realidade.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF2E88" strokeWidth="2">
        <path d="M12 3v18M3 12h18" />
      </svg>
    ),
  },
  {
    title: "Marca do hotel",
    description:
      "Define a experiência White Label final, com branding, conteúdo, catálogo e linguagem do próprio hotel.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF2E88" strokeWidth="2">
        <path d="M4 19 12 5l8 14H4Z" />
      </svg>
    ),
  },
]

export function ModularPlatform() {
  return (
    <Section id="plataforma">
      <SectionHeading
        eyebrow="Plataforma modular"
        title="Uma plataforma modular que cresce com a sua operação"
        lede="Os templates definem a experiência visual. Os módulos definem as capacidades. Os planos definem o espaço de ativação. Cada hotel publica uma experiência própria sobre a mesma base."
        maxWidth="820px"
        marginBottom="38px"
      />
      <div className="mx-auto mb-10 flex max-w-[920px] flex-wrap items-center justify-center gap-3 text-center text-[0.94rem] font-semibold text-muted">
        {["Plano", "Template", "Módulos", "Marca do hotel", "Integrações", "Experiência publicada"].map((step, index, arr) => (
          <div key={step} className="flex items-center gap-3">
            <span className="rounded-full border border-border bg-white px-4 py-2 text-ink">{step}</span>
            {index < arr.length - 1 ? <span className="text-primary">→</span> : null}
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
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
  )
}
