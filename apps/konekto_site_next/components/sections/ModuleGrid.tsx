import { PUBLIC_FEATURE_GROUPS } from "@/content/modules"
import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"
import { StatusPill } from "@/components/ui/StatusPill"

export function ModuleGrid() {
  return (
    <Section id="modulos">
      <SectionHeading
        eyebrow="Recursos para toda a jornada"
        title="Módulos organizados por objetivo da operação"
        lede="A Sevvn organiza seus recursos de acordo com a experiência que o hotel quer construir, e não apenas pela lógica técnica do sistema."
        marginBottom="48px"
      />
      <div className="grid grid-cols-1 gap-[18px] md:grid-cols-2 xl:grid-cols-3">
        {PUBLIC_FEATURE_GROUPS.map((category) => (
          <div key={category.title} className="rounded-[18px] border border-border bg-card p-[22px] text-left">
            <p className="mb-2 text-[13px] font-bold uppercase tracking-[0.04em] text-primary">
              {category.title}
            </p>
            <p className="mb-4 text-[13px] leading-[1.65] text-muted">{category.description}</p>
            <div className="flex flex-col gap-[11px] text-[13.5px]">
              {category.items.map((moduleEntry) => (
                <div key={moduleEntry.featureId} className="flex items-center justify-between gap-3">
                  <span className="text-ink">{moduleEntry.label}</span>
                  <StatusPill status={moduleEntry.status} />
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Section>
  )
}
