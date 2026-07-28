import type { Plan } from "@/content/plans"

type Props = {
  plan: Plan
}

export function PlanCard({ plan }: Props) {
  return (
    <div
      className={`relative rounded-[22px] p-8 ${
        plan.featured ? "border-2 border-primary bg-white" : "border border-border bg-surface"
      }`}
    >
      {plan.featured ? (
        <span className="absolute -top-[13px] left-8 rounded-full bg-primary px-3 py-[5px] text-[11px] font-bold text-white">
          Mais aderente para expansão
        </span>
      ) : null}
      <p className="text-[15px] font-bold text-ink">{plan.name}</p>
      <p className="mt-[6px] text-[12.5px] leading-[1.6] text-muted">{plan.audience}</p>

      <p className="mt-5 text-[34px] font-extrabold text-ink">
        {plan.price}
        {plan.priceSuffix ? (
          <span className="text-[14px] font-semibold text-muted">{plan.priceSuffix}</span>
        ) : null}
      </p>
      {plan.founderNote ? (
        <p className="mt-[6px] text-[11.5px] font-bold text-primary">{plan.founderNote}</p>
      ) : null}

      <p className="mt-4 text-[13px] leading-[1.7] text-muted">{plan.tagline}</p>
      <ul className="mt-5 space-y-2 text-[12.8px] leading-[1.65] text-ink">
        {plan.highlights.map((highlight) => (
          <li key={highlight}>• {highlight}</li>
        ))}
      </ul>

      <a
        href={plan.ctaHref}
        className={`mt-[22px] block rounded-[10px] py-[13px] text-center text-[14px] font-bold no-underline ${
          plan.featured ? "bg-primary text-white" : "bg-card text-ink"
        }`}
      >
        {plan.ctaLabel}
      </a>
    </div>
  )
}
