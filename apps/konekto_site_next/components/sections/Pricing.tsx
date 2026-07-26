import { PLANS } from "@/content/plans";
import { PlanCard } from "@/components/ui/PlanCard";
import { Section } from "@/components/ui/Section";
import { SectionHeading } from "@/components/ui/SectionHeading";

export function Pricing() {
  return (
    <Section id="planos">
      <SectionHeading
        eyebrow="Planos"
        title="Níveis de evolução, não pacotes fechados"
        marginBottom="48px"
      />
      <div className="grid grid-cols-1 items-stretch gap-[22px] sm:grid-cols-3">
        {PLANS.map((plan) => (
          <PlanCard key={plan.id} plan={plan} />
        ))}
      </div>
    </Section>
  );
}
