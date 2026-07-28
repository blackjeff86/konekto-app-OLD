import { STATUS_LABEL, type PublicFeatureStatus } from "@/content/product-roadmap"

const STATUS_CLASSES: Record<PublicFeatureStatus, string> = {
  available: "bg-[#EAF8EF] text-[#137333]",
  "in-development": "bg-primary-soft text-primary-text",
  "coming-soon": "bg-card text-muted",
}

export function StatusPill({ status }: { status: PublicFeatureStatus }) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-3 py-[0.36rem] text-[0.68rem] font-bold uppercase tracking-[0.04em] ${STATUS_CLASSES[status]}`}
    >
      {STATUS_LABEL[status]}
    </span>
  )
}
