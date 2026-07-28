import { Section } from "@/components/ui/Section"

const FOUNDING_HOTEL_BENEFITS = [
  "Condição comercial diferenciada",
  "Implantação prioritária",
  "Canal direto com a equipe da Sevvn",
  "Participação na evolução do produto",
  "Acesso antecipado a determinados recursos",
  "Suporte prioritário durante o piloto",
] as const

const FOUNDING_PARTNER_BENEFITS = [
  "Participação inicial na Rede Sevvn",
  "Condições diferenciadas durante a validação",
  "Destaque inicial na construção da rede",
  "Participação no desenho da experiência",
  "Acesso antecipado ao futuro portal de parceiros",
  "Acompanhamento próximo da equipe",
] as const

export function FoundingClients() {
  return (
    <Section alt paddingY="88px">
      <div className="mx-auto max-w-[760px] text-center">
        <p className="eyebrow">Fundadores</p>
        <h2 className="mt-[10px] text-[30px] font-extrabold leading-[1.2] tracking-[-0.02em] text-ink">
          Um convite para quem quer embarcar desde o início
        </h2>
        <p className="mt-[14px] text-[15px] leading-[1.7] text-muted">
          A Sevvn está sendo construída com ambição de longo prazo e transparência sobre o estágio
          atual. Por isso, faz sentido abrir espaço para hotéis e parceiros fundadores
          participarem dessa evolução com proximidade real.
        </p>
      </div>
      <div className="mx-auto mt-10 grid max-w-[980px] gap-5 lg:grid-cols-2">
        <div className="rounded-[24px] border border-border bg-white p-7">
          <p className="text-[0.78rem] font-bold uppercase tracking-[0.16em] text-primary">Clientes fundadores</p>
          <ul className="mt-5 space-y-3 text-[0.94rem] leading-[1.7] text-muted">
            {FOUNDING_HOTEL_BENEFITS.map((benefit) => (
              <li key={benefit}>• {benefit}</li>
            ))}
          </ul>
        </div>
        <div className="rounded-[24px] border border-border bg-white p-7">
          <p className="text-[0.78rem] font-bold uppercase tracking-[0.16em] text-primary">Parceiros fundadores</p>
          <ul className="mt-5 space-y-3 text-[0.94rem] leading-[1.7] text-muted">
            {FOUNDING_PARTNER_BENEFITS.map((benefit) => (
              <li key={benefit}>• {benefit}</li>
            ))}
          </ul>
        </div>
      </div>
    </Section>
  )
}
