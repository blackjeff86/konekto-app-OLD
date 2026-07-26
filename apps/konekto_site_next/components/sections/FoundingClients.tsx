import { Section } from "@/components/ui/Section";

export function FoundingClients() {
  return (
    <Section alt paddingY="88px">
      <div className="mx-auto max-w-[760px] text-center">
        <p className="eyebrow">Clientes fundadores</p>
        <h2 className="mt-[10px] text-[30px] font-extrabold leading-[1.2] tracking-[-0.02em] text-ink">
          Construa a plataforma com a gente
        </h2>
        <p className="mt-[14px] text-[15px] leading-[1.7] text-muted">
          Os primeiros hotéis participam diretamente da construção da plataforma: valor
          promocional vitalício, implantação prioritária, canal direto com nosso time e
          participação ativa na evolução do produto.
        </p>
      </div>
    </Section>
  );
}
