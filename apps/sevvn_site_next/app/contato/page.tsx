import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { ContactForms } from "@/components/forms/ContactForms"
import { PageHero } from "@/components/ui/PageHero"
import { Section } from "@/components/ui/Section"

export const metadata: Metadata = {
  title: "Contato Sevvn",
  description: "Agende uma demonstração, manifeste interesse como parceiro ou converse sobre uma operação Enterprise com a equipe da Sevvn.",
}

export default function ContatoPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Contato"
          title="Vamos conversar sobre a sua operação ou parceria"
          description="A Sevvn já pode abrir conversas com hotéis, parceiros locais e operações de maior complexidade. Escolha o tipo de contato e envie sua mensagem."
        />
        <Section paddingY="84px">
          <div id="hotel-demo" className="scroll-mt-28">
            <ContactForms />
          </div>
          <div className="mt-10 grid gap-5 lg:grid-cols-3">
            <div id="partner-interest" className="scroll-mt-28 rounded-[22px] border border-border bg-card p-6">
              <p className="text-[0.78rem] font-bold uppercase tracking-[0.16em] text-primary">Parceiros</p>
              <p className="mt-3 text-[0.94rem] leading-[1.7] text-muted">
                Restaurantes, passeios, transfers, spas, experiências locais e empresas parceiras
                podem iniciar a conversa com a Sevvn desde agora.
              </p>
            </div>
            <div id="enterprise" className="scroll-mt-28 rounded-[22px] border border-border bg-card p-6">
              <p className="text-[0.78rem] font-bold uppercase tracking-[0.16em] text-primary">Enterprise</p>
              <p className="mt-3 text-[0.94rem] leading-[1.7] text-muted">
                Para redes, grupos, resorts e operações multiunidade, a conversa pode incluir
                governança, integrações específicas, módulos exclusivos e arquitetura dedicada.
              </p>
            </div>
            <div className="rounded-[22px] border border-border bg-card p-6">
              <p className="text-[0.78rem] font-bold uppercase tracking-[0.16em] text-primary">Captação provisória</p>
              <p className="mt-3 text-[0.94rem] leading-[1.7] text-muted">
                Nesta etapa, o formulário institucional já registra o interesse por meio do
                endpoint do site. Isso nos permite preparar a frente comercial sem depender da API
                principal do produto para renderizar ou captar a Home.
              </p>
            </div>
          </div>
        </Section>
      </main>
      <SiteFooter />
    </>
  )
}
