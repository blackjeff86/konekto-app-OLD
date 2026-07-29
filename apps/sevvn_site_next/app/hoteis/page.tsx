import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { HotelBenefits } from "@/components/sections/HotelBenefits"
import { GuestJourney } from "@/components/sections/GuestJourney"
import { Pricing } from "@/components/sections/Pricing"
import { UseCases } from "@/components/sections/UseCases"

export const metadata: Metadata = {
  title: "Sevvn para hotéis e pousadas",
  description: "Entenda como a Sevvn ajuda hotéis, pousadas, resorts e redes a conectar a experiência do hóspede e a operação do hotel.",
}

export default function HoteisPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Para hotéis"
          title="Uma experiência melhor para o hóspede. Uma operação mais conectada para o hotel."
          description="A Sevvn foi desenhada para hotéis, pousadas, resorts e grupos que querem organizar sua jornada digital sem transformar a operação em um mosaico de ferramentas desconectadas."
        />
        <HotelBenefits />
        <GuestJourney />
        <UseCases />
        <Pricing />
      </main>
      <SiteFooter />
    </>
  )
}
