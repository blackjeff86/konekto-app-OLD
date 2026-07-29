import type { Metadata } from "next"
import { SiteHeader } from "@/components/layout/SiteHeader"
import { SiteFooter } from "@/components/layout/SiteFooter"
import { PageHero } from "@/components/ui/PageHero"
import { ModuleGrid } from "@/components/sections/ModuleGrid"
import { RoadmapGrid } from "@/components/sections/RoadmapGrid"

export const metadata: Metadata = {
  title: "Recursos e módulos da Sevvn",
  description: "Explore os recursos da Sevvn organizados por jornada, operação e estágio público de disponibilidade.",
}

export default function RecursosPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <PageHero
          eyebrow="Recursos"
          title="Recursos organizados para a jornada do hóspede e da operação"
          description="A Sevvn apresenta seus módulos por objetivo de negócio e estágio de evolução, para que hotéis e parceiros entendam claramente o que já está disponível e o que está em construção."
        />
        <ModuleGrid />
        <section className="mx-auto max-w-[1180px] px-8 py-20">
          <RoadmapGrid />
        </section>
      </main>
      <SiteFooter />
    </>
  )
}
