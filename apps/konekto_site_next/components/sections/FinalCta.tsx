import { Section } from "@/components/ui/Section"

export function FinalCta() {
  return (
    <Section paddingY="88px" className="bg-ink">
      <div className="text-center">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/logo/sevvn-wordmark-dark-bg.svg"
          alt="Sevvn"
          className="mx-auto mb-6 h-7 w-auto"
        />
        <h2 className="text-[32px] font-extrabold leading-[1.15] tracking-[-0.02em] text-white">
          A plataforma que conecta a experiência da hospedagem começa aqui
        </h2>
        <p className="mx-auto mt-4 max-w-[760px] text-[0.98rem] leading-[1.8] text-white/68">
          Se você quer modernizar a jornada do hóspede, conectar sua operação e participar da
          próxima evolução da hospitalidade, este é o momento certo para conversar com a Sevvn.
        </p>
        <div className="mt-[26px] flex flex-wrap justify-center gap-3">
          <a
            href="/contato#hotel-demo"
            className="inline-block rounded-[10px] bg-primary px-[30px] py-[15px] text-[15px] font-bold text-white no-underline"
          >
            Agendar demonstração
          </a>
          <a
            href="/contato#partner-interest"
            className="inline-block rounded-[10px] border border-white/20 bg-white/5 px-[30px] py-[15px] text-[15px] font-bold text-white no-underline"
          >
            Quero ser parceiro
          </a>
        </div>
      </div>
    </Section>
  )
}
