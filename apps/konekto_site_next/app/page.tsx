import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { Hero } from "@/components/sections/Hero"
import { PlatformVision } from "@/components/sections/PlatformVision"
import { HotelBenefits } from "@/components/sections/HotelBenefits"
import { GuestJourney } from "@/components/sections/GuestJourney"
import { EcosystemSection } from "@/components/sections/EcosystemSection"
import { ProductSurfaces } from "@/components/sections/ProductSurfaces"
import { ModularPlatform } from "@/components/sections/ModularPlatform"
import { ModuleGrid } from "@/components/sections/ModuleGrid"
import { TemplatesOverview } from "@/components/sections/TemplatesOverview"
import { PartnerNetwork } from "@/components/sections/PartnerNetwork"
import { UseCases } from "@/components/sections/UseCases"
import { PublicRoadmapSummary } from "@/components/sections/PublicRoadmapSummary"
import { Pricing } from "@/components/sections/Pricing"
import { FoundingClients } from "@/components/sections/FoundingClients"
import { Faq } from "@/components/sections/Faq"
import { FinalCta } from "@/components/sections/FinalCta"

export default function Home() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        <PlatformVision />
        <HotelBenefits />
        <GuestJourney />
        <EcosystemSection />
        <ProductSurfaces />
        <ModularPlatform />
        <ModuleGrid />
        <TemplatesOverview />
        <PartnerNetwork />
        <UseCases />
        <PublicRoadmapSummary />
        <Pricing />
        <FoundingClients />
        <Faq />
        <FinalCta />
      </main>
      <SiteFooter />
    </>
  )
}
