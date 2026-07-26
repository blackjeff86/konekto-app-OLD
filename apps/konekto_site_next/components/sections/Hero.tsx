export function Hero() {
  return (
    <header className="pb-20 pt-24">
      <div className="mx-auto max-w-[860px] px-8 text-center">
        <span className="inline-flex items-center rounded-full bg-primary-soft px-[14px] py-[7px] text-[12.5px] font-bold tracking-[0.02em] text-primary-text">
          Guest Experience Platform
        </span>
        <h1 className="mt-[26px] text-[56px] font-extrabold leading-[1.08] tracking-[-0.025em] text-ink">
          Uma plataforma.
          <br />
          Múltiplos módulos.
          <br />
          <span className="text-primary">Uma única experiência.</span>
        </h1>
        <p className="mx-auto mt-6 max-w-[620px] text-[18px] leading-[1.6] text-muted">
          A Sevvn não entrega um aplicativo fechado. Entrega uma plataforma modular de Guest
          Experience, na qual o app é só a interface: a inteligência, a arquitetura e a evolução
          contínua vivem na plataforma.
        </p>
        <div className="mt-9 flex flex-wrap justify-center gap-[14px]">
          <a
            href="#planos"
            className="rounded-[10px] bg-primary px-7 py-[15px] text-[15px] font-bold text-white no-underline"
          >
            Ver planos
          </a>
          <a
            href="#como-funciona"
            className="rounded-[10px] bg-card px-7 py-[15px] text-[15px] font-bold text-ink no-underline"
          >
            Como funciona
          </a>
        </div>
      </div>
    </header>
  );
}
