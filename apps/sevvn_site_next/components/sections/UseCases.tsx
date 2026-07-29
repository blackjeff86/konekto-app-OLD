import { USE_CASES } from "@/content/use-cases"
import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"

export function UseCases() {
  return (
    <Section id="casos-de-uso" paddingY="88px">
      <SectionHeading
        eyebrow="Casos de uso"
        title="Cenários conceituais para diferentes perfis de operação"
        lede="Não são clientes reais. São leituras de como a Sevvn se adapta a contextos diferentes sem deixar de ser a mesma plataforma."
        maxWidth="760px"
        marginBottom="44px"
      />
      <div className="grid gap-5 lg:grid-cols-2">
        {USE_CASES.map((useCase) => (
          <div key={useCase.title} className="rounded-[24px] border border-border bg-surface p-7">
            <p className="text-[0.76rem] font-bold uppercase tracking-[0.18em] text-primary">{useCase.subtitle}</p>
            <h3 className="mt-3 text-[1.16rem] font-bold text-ink">{useCase.title}</h3>
            <p className="mt-3 text-[0.95rem] leading-[1.75] text-muted">{useCase.summary}</p>
            <div className="mt-5 flex flex-wrap gap-2">
              {useCase.highlights.map((highlight) => (
                <span key={highlight} className="rounded-full border border-border bg-white px-3 py-[0.55rem] text-[0.8rem] text-ink">
                  {highlight}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Section>
  )
}
