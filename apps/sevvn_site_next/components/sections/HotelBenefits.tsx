import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"

const BENEFITS = [
  "Menos ligações e menos deslocamentos até a recepção para tarefas repetitivas.",
  "Mais autonomia para o hóspede durante a estadia.",
  "Mais pedidos, reservas de serviços e oportunidades de receita.",
  "Comunicação centralizada entre hotel e hóspede.",
  "Equipe mais livre para o atendimento que realmente exige presença humana.",
  "Marca do hotel fortalecida em toda a experiência digital.",
  "Capacidade de ativar novos recursos sem trocar de plataforma.",
  "Base preparada para integrações, analytics e expansão futura.",
] as const

export function HotelBenefits() {
  return (
    <Section id="hoteis" alt>
      <SectionHeading
        eyebrow="Para hotéis"
        title="O que muda para o seu hotel"
        lede="A Sevvn não existe para digitalizar por digitalizar. Ela existe para reduzir fricção, organizar a operação e abrir espaço para uma experiência melhor e mais rentável."
        maxWidth="760px"
        marginBottom="44px"
      />
      <div className="grid gap-4 md:grid-cols-2">
        {BENEFITS.map((benefit, index) => (
          <div key={benefit} className="rounded-[22px] border border-border bg-white p-6">
            <div className="flex items-start gap-4">
              <span className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary text-[0.8rem] font-bold text-white">
                {String(index + 1).padStart(2, "0")}
              </span>
              <p className="text-[0.96rem] leading-[1.7] text-ink">{benefit}</p>
            </div>
          </div>
        ))}
      </div>
    </Section>
  )
}
