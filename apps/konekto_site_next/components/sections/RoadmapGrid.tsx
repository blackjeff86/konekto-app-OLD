import { PUBLIC_FEATURES, STATUS_LABEL, type PublicFeatureStatus } from "@/content/product-roadmap"
import { StatusPill } from "@/components/ui/StatusPill"

const ORDER: PublicFeatureStatus[] = ["available", "in-development", "coming-soon"]

export function RoadmapGrid() {
  return (
    <div className="space-y-10">
      {ORDER.map((status) => {
        const items = PUBLIC_FEATURES.filter((feature) => feature.status === status)
        return (
          <section key={status}>
            <div className="mb-5 flex items-center gap-3">
              <StatusPill status={status} />
              <h2 className="text-[1.4rem] font-bold text-ink">{STATUS_LABEL[status]}</h2>
            </div>
            <div className="grid gap-4 lg:grid-cols-2">
              {items.map((feature) => (
                <article key={feature.id} className="rounded-[22px] border border-border bg-white p-6">
                  <p className="text-[0.72rem] font-bold uppercase tracking-[0.14em] text-primary">
                    {feature.category}
                  </p>
                  <h3 className="mt-3 text-[1rem] font-bold text-ink">{feature.displayName}</h3>
                  <p className="mt-3 text-[0.92rem] leading-[1.7] text-muted">{feature.description}</p>
                </article>
              ))}
            </div>
          </section>
        )
      })}
    </div>
  )
}
