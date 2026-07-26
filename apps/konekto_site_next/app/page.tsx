import { SiteHeader } from "@/components/layout/SiteHeader";
import { SiteFooter } from "@/components/layout/SiteFooter";
import { Hero } from "@/components/sections/Hero";
import { HowItWorks } from "@/components/sections/HowItWorks";
import { ModularPlatform } from "@/components/sections/ModularPlatform";
import { Templates } from "@/components/sections/Templates";
import { ModuleGrid } from "@/components/sections/ModuleGrid";
import { ContinuousEvolution } from "@/components/sections/ContinuousEvolution";
import { Pricing } from "@/components/sections/Pricing";
import { FoundingClients } from "@/components/sections/FoundingClients";
import { Faq } from "@/components/sections/Faq";
import { FinalCta } from "@/components/sections/FinalCta";

export default function Home() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        <HowItWorks />
        <ModularPlatform />
        <Templates />
        <ModuleGrid />
        <ContinuousEvolution />
        <Pricing />
        <FoundingClients />
        <Faq />
        <FinalCta />
      </main>
      <SiteFooter />
    </>
  );
}
