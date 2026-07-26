import { Section } from "@/components/ui/Section";

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
          Sua plataforma de Guest Experience começa aqui
        </h2>
        <a
          href="#planos"
          className="mt-[26px] inline-block rounded-[10px] bg-primary px-[30px] py-[15px] text-[15px] font-bold text-white no-underline"
        >
          Agendar demo
        </a>
      </div>
    </Section>
  );
}
