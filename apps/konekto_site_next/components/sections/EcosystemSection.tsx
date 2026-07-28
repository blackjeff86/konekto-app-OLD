import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"

const ECOSYSTEM_ITEMS = [
  "Aplicativo do hóspede",
  "Portal do hotel",
  "Sevvn Admin",
  "Módulos e serviços",
  "Integrações PMS / ERP",
  "Comunicação e operação",
  "Dados e analytics",
  "Rede de parceiros e experiências",
] as const

export function EcosystemSection() {
  return (
    <Section id="ecossistema" alt>
      <SectionHeading
        eyebrow="Ecossistema Sevvn"
        title="A plataforma que conecta toda a experiência da hospedagem"
        lede="Uma representação comercial do que a Sevvn já conecta hoje e do que está sendo preparado para a próxima fase da plataforma."
        maxWidth="760px"
        marginBottom="46px"
      />
      <div className="rounded-[34px] border border-border bg-ink p-6 text-white shadow-[0_34px_80px_-48px_rgba(22,24,29,0.5)] sm:p-10">
        <p className="text-center text-[0.78rem] font-bold uppercase tracking-[0.24em] text-primary">
          Sevvn Platform
        </p>
        <div className="mt-8 grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          {ECOSYSTEM_ITEMS.map((item) => (
            <div key={item} className="rounded-[18px] border border-white/10 bg-white/[0.04] px-4 py-4 text-[0.92rem] text-white/88">
              {item}
            </div>
          ))}
        </div>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3 text-center text-[0.9rem] font-medium text-white/70">
          <span>Hotel</span>
          <span className="text-primary">↔</span>
          <span>Equipe</span>
          <span className="text-primary">↔</span>
          <span>Hóspede</span>
          <span className="text-primary">↔</span>
          <span>Parceiros</span>
        </div>
      </div>
    </Section>
  )
}
