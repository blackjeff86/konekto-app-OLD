import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { Section } from "@/components/ui/Section"

export const metadata: Metadata = {
  title: "Sobre a Sevvn",
  description: "Conheça a visão da Sevvn para a hospitalidade conectada e a construção de uma plataforma de longo prazo para hotéis, hóspedes e parceiros.",
}

export default function SobrePage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Sobre"
          title="Uma plataforma de longo prazo para a hospitalidade"
          description="A Sevvn nasceu da percepção de que a experiência do hóspede, a operação do hotel e as oportunidades de serviços e parcerias não deveriam viver em sistemas isolados."
        />
        <Section paddingY="88px">
          <div className="mx-auto max-w-[820px] space-y-6 text-[1rem] leading-[1.85] text-muted">
            <p>
              O que o hóspede enxerga é apenas a ponta visível da jornada. Por trás dela existem
              operação, conteúdo, regras, integrações, equipes, dados, fornecedores, serviços e
              oportunidades de relacionamento que precisam funcionar como um ecossistema.
            </p>
            <p>
              A Sevvn está sendo construída para conectar essa jornada inteira com uma lógica
              modular, White Label e preparada para crescer com cada hotel, pousada, resort ou
              operação multiunidade.
            </p>
            <p>
              Nossa visão é ambiciosa, mas a comunicação da plataforma precisa ser honesta. Por
              isso, o site separa claramente o que já está disponível, o que está em construção e
              o que pertence ao próximo ciclo de evolução pública da Sevvn.
            </p>
          </div>
        </Section>
      </main>
      <SiteFooter />
    </>
  )
}
