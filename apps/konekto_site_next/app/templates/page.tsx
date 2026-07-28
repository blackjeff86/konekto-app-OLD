import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { TemplatesOverview } from "@/components/sections/TemplatesOverview"
import { Section } from "@/components/ui/Section"

export const metadata: Metadata = {
  title: "Templates da Sevvn",
  description: "Conheça Aura, Bosque, Elite, Pulse e Horizon como identidades visuais diferentes sobre a mesma plataforma Sevvn.",
}

export default function TemplatesPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Templates"
          title="Cinco experiências visuais. A mesma lógica de plataforma."
          description="Aura, Bosque, Elite, Pulse e Horizon não são aplicativos diferentes. São interpretações visuais diferentes da mesma estrutura de módulos, dados e operação."
        />
        <TemplatesOverview />
        <Section paddingY="72px">
          <div className="mx-auto max-w-[760px] text-center">
            <p className="text-[0.98rem] leading-[1.8] text-muted">
              Nesta fase do reposicionamento institucional, optamos por não exibir os prints dos
              templates na Home. O ponto principal aqui é reforçar a lógica correta: templates
              definem identidade visual; módulos definem recursos; a plataforma permanece a mesma.
            </p>
          </div>
        </Section>
      </main>
      <SiteFooter />
    </>
  )
}
