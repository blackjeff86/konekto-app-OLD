import { Section } from "@/components/ui/Section";

export function ContinuousEvolution() {
  return (
    <Section paddingY="80px" className="bg-ink">
      <div className="mx-auto max-w-[700px] text-center">
        <p className="eyebrow">Evolução contínua</p>
        <h2 className="mt-[10px] text-[32px] font-extrabold leading-[1.15] tracking-[-0.02em] text-white">
          Seu aplicativo continua evoluindo, sem reconstrução e sem migração
        </h2>
        <p className="mt-4 text-[15.5px] leading-[1.7] text-white/65">
          Ao contratar a plataforma, novos módulos e experiências chegam continuamente, sem
          trocar de aplicativo e sem perder configurações ou dados. Isso protege completamente o
          investimento do seu hotel a longo prazo.
        </p>
      </div>
    </Section>
  );
}
