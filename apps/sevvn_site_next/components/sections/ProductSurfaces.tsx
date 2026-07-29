import { PRODUCT_SURFACES } from "@/content/products"
import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"
import { StatusPill } from "@/components/ui/StatusPill"

export function ProductSurfaces() {
  return (
    <Section id="produtos" paddingY="88px">
      <SectionHeading
        eyebrow="Produtos e interfaces"
        title="Quatro camadas do ecossistema Sevvn"
        lede="A plataforma não se resume à experiência do hóspede. Ela organiza também a operação do hotel, a administração central da Sevvn e a futura rede de parceiros."
        maxWidth="780px"
        marginBottom="46px"
      />
      <div className="grid gap-5 lg:grid-cols-2">
        {PRODUCT_SURFACES.map((surface) => (
          <div key={surface.id} className="rounded-[24px] border border-border bg-white p-7">
            <div className="flex flex-wrap items-center gap-3">
              <h3 className="text-[1.12rem] font-bold text-ink">{surface.name}</h3>
              <StatusPill status={surface.status} />
            </div>
            <p className="mt-4 text-[1rem] font-semibold text-ink">{surface.title}</p>
            <p className="mt-3 text-[0.95rem] leading-[1.75] text-muted">{surface.description}</p>
            <ul className="mt-5 space-y-2 text-[0.92rem] text-ink">
              {surface.bullets.map((bullet) => (
                <li key={bullet}>• {bullet}</li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </Section>
  )
}
