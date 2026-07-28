import { PLATFORM_THESIS } from "@/content/brand"
import { Section } from "@/components/ui/Section"

const PILLARS = [
  "Experiência do hóspede",
  "Operação do hotel",
  "Integrações",
  "Módulos",
  "Parceiros",
  "Evolução contínua",
]

export function PlatformVision() {
  return (
    <Section id="visao" paddingY="88px">
      <div className="grid gap-10 lg:grid-cols-[1.1fr_0.9fr] lg:items-start">
        <div>
          <p className="eyebrow">{PLATFORM_THESIS.eyebrow}</p>
          <h2 className="mt-3 max-w-[680px] text-[clamp(2rem,4vw,3rem)] font-extrabold leading-[1.08] tracking-[-0.03em] text-ink">
            {PLATFORM_THESIS.title}
          </h2>
          <p className="mt-5 max-w-[640px] text-[1rem] leading-[1.8] text-muted">
            {PLATFORM_THESIS.lede}
          </p>
        </div>
        <div className="rounded-[28px] border border-border bg-surface p-7 shadow-[0_24px_60px_-42px_rgba(22,24,29,0.25)]">
          <p className="text-[0.9rem] font-semibold text-ink">Os pilares da plataforma</p>
          <div className="mt-5 flex flex-wrap gap-3">
            {PILLARS.map((pillar) => (
              <span
                key={pillar}
                className="rounded-full border border-border bg-surface-alt px-4 py-2 text-[0.86rem] font-medium text-ink"
              >
                {pillar}
              </span>
            ))}
          </div>
          <p className="mt-6 text-[0.92rem] leading-[1.75] text-muted">
            O resultado não é um app isolado. É uma infraestrutura comercial e operacional que
            sustenta a jornada do hóspede e a evolução do hotel ao longo do tempo.
          </p>
        </div>
      </div>
    </Section>
  )
}
