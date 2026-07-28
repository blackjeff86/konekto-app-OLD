import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { RoadmapGrid } from "@/components/sections/RoadmapGrid"

export const metadata: Metadata = {
  title: "Roadmap da Sevvn",
  description: "Veja o que já está disponível, o que está em desenvolvimento e o que faz parte da próxima evolução pública da Sevvn.",
}

export default function RoadmapPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Roadmap"
          title="O futuro da experiência hoteleira está sendo construído agora"
          description="A Sevvn comunica publicamente o estágio do produto com clareza: disponível, em desenvolvimento e em breve. Sem promessas irreais e sem esconder o que ainda está em construção."
        />
        <section className="mx-auto max-w-[1180px] px-8 py-20">
          <RoadmapGrid />
        </section>
      </main>
      <SiteFooter />
    </>
  )
}
