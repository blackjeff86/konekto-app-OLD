import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { Pricing } from "@/components/sections/Pricing"

export const metadata: Metadata = {
  title: "Planos da Sevvn",
  description: "Compare Essential, Premium e Enterprise como níveis de evolução da plataforma Sevvn.",
}

export default function PlanosPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Planos"
          title="Escolha o nível de evolução que faz sentido para a sua operação"
          description="Os planos da Sevvn não empacotam apenas um aplicativo. Eles definem espaço para crescimento, templates, governança, integrações e personalização dentro da plataforma."
        />
        <Pricing />
      </main>
      <SiteFooter />
    </>
  )
}
