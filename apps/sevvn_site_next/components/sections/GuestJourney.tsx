import { Section } from "@/components/ui/Section"
import { SectionHeading } from "@/components/ui/SectionHeading"
import { StatusPill } from "@/components/ui/StatusPill"
import type { PublicFeatureStatus } from "@/content/product-roadmap"

const JOURNEY_STEPS: Array<{
  stage: string
  description: string
  status: PublicFeatureStatus
}> = [
  {
    stage: "Antes da chegada",
    description: "Preparação da jornada, contexto da hospedagem e futuros fluxos de ativação.",
    status: "in-development",
  },
  {
    stage: "Check-in",
    description: "Fluxos operacionais atuais e a próxima evolução para check-in digital.",
    status: "in-development",
  },
  {
    stage: "Informações da estadia",
    description: "Acesso a dados da hospedagem, quarto e orientações úteis.",
    status: "available",
  },
  {
    stage: "Wi-Fi e orientações",
    description: "Camada de suporte prático para o hóspede já disponível na plataforma.",
    status: "available",
  },
  {
    stage: "Serviços e pedidos",
    description: "Room Service, restaurantes, passeios, spa e estrutura para novos serviços dentro do escopo validado do piloto.",
    status: "available",
  },
  {
    stage: "Mensagens com a equipe",
    description: "Comunicação operacional centralizada dentro da jornada do hóspede.",
    status: "available",
  },
  {
    stage: "Promoções e benefícios",
    description: "Ações comerciais e de relacionamento no contexto da estadia, em uso controlado nesta fase.",
    status: "available",
  },
  {
    stage: "Check-out",
    description: "Próxima camada da jornada digital em evolução na plataforma.",
    status: "in-development",
  },
  {
    stage: "Fidelização e retorno",
    description: "Programa de fidelidade, benefícios e recorrência da experiência.",
    status: "in-development",
  },
]

export function GuestJourney() {
  return (
    <Section id="jornada" paddingY="88px">
      <SectionHeading
        eyebrow="Jornada do hóspede"
        title="Uma jornada mais simples para o hóspede. Mais conectada para o hotel."
        lede="A Sevvn organiza a experiência por etapas reais da hospedagem e deixa claro o que já está disponível, o que está em desenvolvimento e o que faz parte da próxima evolução."
        maxWidth="820px"
        marginBottom="46px"
      />
      <div className="grid gap-4 lg:grid-cols-3">
        {JOURNEY_STEPS.map((step) => (
          <div key={step.stage} className="rounded-[22px] border border-border bg-surface p-6">
            <StatusPill status={step.status} />
            <h3 className="mt-4 text-[1.05rem] font-bold text-ink">{step.stage}</h3>
            <p className="mt-3 text-[0.95rem] leading-[1.7] text-muted">{step.description}</p>
          </div>
        ))}
      </div>
    </Section>
  )
}
