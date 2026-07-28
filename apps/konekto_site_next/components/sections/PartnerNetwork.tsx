import { PARTNER_BENEFITS, PARTNER_CATEGORIES } from "@/content/partners"
import { Section } from "@/components/ui/Section"
import { StatusPill } from "@/components/ui/StatusPill"

export function PartnerNetwork() {
  return (
    <Section id="parceiros" alt>
      <div className="grid gap-8 lg:grid-cols-[1.05fr_0.95fr]">
        <div>
          <p className="eyebrow">Rede Sevvn</p>
          <div className="mt-3 flex flex-wrap items-center gap-3">
            <h2 className="text-[clamp(2rem,4vw,3rem)] font-extrabold leading-[1.08] tracking-[-0.03em] text-ink">
              Uma rede que conecta hóspedes a experiências confiáveis.
            </h2>
            <StatusPill status="in-development" />
          </div>
          <p className="mt-5 max-w-[640px] text-[1rem] leading-[1.8] text-muted">
            A Rede Sevvn permitirá que hotéis ofereçam restaurantes, passeios, transfers, spas,
            comércio local e outras experiências diretamente na jornada digital do hóspede, sem
            transformar o hotel em operador de tudo sozinho. Esta camada ainda está em evolução e
            não deve ser tratada como rede totalmente lançada.
          </p>
          <div className="mt-7 flex flex-wrap gap-3">
            {["Parceiros próprios do hotel", "Parceiros homologados pela Sevvn", "Modelo híbrido"].map((model) => (
              <span key={model} className="rounded-full border border-border bg-white px-4 py-2 text-[0.86rem] font-medium text-ink">
                {model}
              </span>
            ))}
          </div>
        </div>
        <div className="rounded-[28px] border border-border bg-white p-7">
          <p className="text-[0.94rem] font-semibold text-ink">Quem pode participar</p>
          <div className="mt-4 flex flex-wrap gap-2">
            {PARTNER_CATEGORIES.map((category) => (
              <span key={category} className="rounded-full bg-card px-3 py-2 text-[0.82rem] text-muted">
                {category}
              </span>
            ))}
          </div>
          <ul className="mt-6 space-y-3 text-[0.92rem] leading-[1.7] text-muted">
            {PARTNER_BENEFITS.map((benefit) => (
              <li key={benefit}>• {benefit}</li>
            ))}
          </ul>
          <a
            href="/contato#partner-interest"
            className="mt-7 inline-block rounded-[12px] bg-primary px-6 py-3 text-[0.92rem] font-bold text-white no-underline"
          >
            Quero participar desde o início
          </a>
        </div>
      </div>
    </Section>
  )
}
