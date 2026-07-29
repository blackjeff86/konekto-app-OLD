import { getFeaturesByStatus } from "@/content/product-roadmap"
import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"
import { StatusPill } from "@/components/ui/StatusPill"

const ROADMAP_COLUMNS = [
  {
    status: "available" as const,
    title: "Disponível",
    description: "O que já faz parte da plataforma e pode ser demonstrado hoje.",
  },
  {
    status: "in-development" as const,
    title: "Em desenvolvimento",
    description: "O que já está no próximo ciclo imediato de evolução da Sevvn.",
  },
  {
    status: "coming-soon" as const,
    title: "Em breve",
    description: "O que faz parte do roadmap público e da visão da plataforma.",
  },
]

export function PublicRoadmapSummary() {
  return (
    <Section id="roadmap" alt>
      <SectionHeading
        eyebrow="Roadmap público"
        title="O futuro da experiência hoteleira está sendo construído agora"
        lede="A Sevvn comunica o estágio do produto com transparência: o que já está pronto, o que está em construção e o que pertence à próxima evolução da plataforma."
        maxWidth="820px"
        marginBottom="42px"
      />
      <div className="grid gap-5 lg:grid-cols-3">
        {ROADMAP_COLUMNS.map((column) => {
          const items = getFeaturesByStatus(column.status).slice(0, 6)
          return (
            <div key={column.status} className="rounded-[24px] border border-border bg-white p-6">
              <div className="flex items-center justify-between gap-3">
                <h3 className="text-[1.02rem] font-bold text-ink">{column.title}</h3>
                <StatusPill status={column.status} />
              </div>
              <p className="mt-3 text-[0.9rem] leading-[1.65] text-muted">{column.description}</p>
              <ul className="mt-5 space-y-2 text-[0.9rem] text-ink">
                {items.map((item) => (
                  <li key={item.id}>• {item.displayName}</li>
                ))}
              </ul>
            </div>
          )
        })}
      </div>
      <div className="mt-9 text-center">
        <a
          href="/roadmap"
          className="inline-block rounded-[12px] border border-border-strong bg-white px-6 py-3 text-[0.92rem] font-semibold text-ink no-underline"
        >
          Ver roadmap completo
        </a>
      </div>
    </Section>
  )
}
