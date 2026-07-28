import { PLANS } from "@/content/plans"
import { PlanCard } from "@/components/ui/PlanCard"
import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"

export function Pricing() {
  return (
    <Section id="planos">
      <SectionHeading
        eyebrow="Planos"
        title="Níveis de evolução, não pacotes fechados"
        lede="Essential, Premium e Enterprise são formas diferentes de ativar a mesma plataforma, com espaço crescente para personalização, módulos, integrações e governança."
        marginBottom="48px"
      />
      <div className="grid grid-cols-1 items-stretch gap-[22px] sm:grid-cols-3">
        {PLANS.map((plan) => (
          <PlanCard key={plan.id} plan={plan} />
        ))}
      </div>
      <p className="mx-auto mt-8 max-w-[820px] text-center text-[0.92rem] leading-[1.75] text-muted">
        A comparação entre planos não depende de uma contagem fixa de módulos. Ela depende do
        grau de evolução da operação, do nível de personalização desejado e da profundidade das
        integrações e da governança exigidas pelo cenário.
      </p>
    </Section>
  )
}
