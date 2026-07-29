import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { PlatformVision } from "@/components/sections/PlatformVision"
import { EcosystemSection } from "@/components/sections/EcosystemSection"
import { ProductSurfaces } from "@/components/sections/ProductSurfaces"
import { ModularPlatform } from "@/components/sections/ModularPlatform"
import { PublicRoadmapSummary } from "@/components/sections/PublicRoadmapSummary"

export const metadata: Metadata = {
  title: "Plataforma Sevvn",
  description: "Visão completa da plataforma Sevvn, das interfaces operacionais e da arquitetura modular que sustenta a experiência do hóspede.",
}

export default function PlataformaPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Plataforma"
          title="A infraestrutura digital da hospitalidade moderna"
          description="A Sevvn conecta a jornada do hóspede, a operação do hotel, a administração central e a próxima camada de parceiros e experiências em uma única plataforma."
        />
        <PlatformVision />
        <EcosystemSection />
        <ProductSurfaces />
        <ModularPlatform />
        <PublicRoadmapSummary />
      </main>
      <SiteFooter />
    </>
  )
}
