import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { PartnerNetwork } from "@/components/sections/PartnerNetwork"
import { FoundingClients } from "@/components/sections/FoundingClients"

export const metadata: Metadata = {
  title: "Rede Sevvn e parceiros",
  description: "Conheça a visão da Rede Sevvn para parceiros locais, experiências e empresas que desejam participar da jornada da hospitalidade conectada.",
}

export default function ParceirosPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Para parceiros"
          title="A Rede Sevvn está sendo construída para conectar hóspedes a experiências confiáveis"
          description="Restaurantes, passeios, transfers, spas, lojas e parceiros corporativos poderão participar da jornada digital da hospedagem em um modelo progressivo e transparente."
          badge="Rede Sevvn em desenvolvimento"
        />
        <PartnerNetwork />
        <FoundingClients />
      </main>
      <SiteFooter />
    </>
  )
}
