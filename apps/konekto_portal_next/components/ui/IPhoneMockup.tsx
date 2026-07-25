/**
 * Moldura de iPhone recente (dynamic island, cantos bem arredondados,
 * indicador de home) em volta de um print real de tela — usado no seletor
 * de aparência pra mostrar a home de cada template exatamente como o
 * Stitch desenhou, não uma recriação simplificada. O print é mais alto que
 * a "janela" do celular (é a página inteira, scrollável) — por isso o
 * miolo rola (overflow-y-auto) em vez de cortar o conteúdo.
 */
export function IPhoneMockup({ imageSrc, imageAlt }: { imageSrc: string; imageAlt: string }) {
  return (
    <div className="relative h-[600px] w-[292px] shrink-0 rounded-[46px] bg-ink p-[14px] shadow-[0_30px_60px_-15px_rgba(22,24,29,0.35)]">
      <div className="relative h-full w-full overflow-hidden rounded-[34px] bg-white">
        <div className="scrollbar-hidden h-full w-full overflow-y-auto">
          {/* eslint-disable-next-line @next/next/no-img-element -- print estático local, altura real varia por template; next/image exigiria width/height fixos que distorceriam a proporção. */}
          <img src={imageSrc} alt={imageAlt} className="w-full" />
        </div>
        {/* Dynamic island */}
        <div className="pointer-events-none absolute top-2.5 left-1/2 h-7 w-[100px] -translate-x-1/2 rounded-full bg-ink" />
        {/* Indicador de home */}
        <div className="pointer-events-none absolute bottom-1.5 left-1/2 h-1 w-[120px] -translate-x-1/2 rounded-full bg-ink/60" />
      </div>
      {/* Botões laterais */}
      <div className="absolute top-[120px] -left-[2px] h-8 w-[3px] rounded-l bg-ink" />
      <div className="absolute top-[165px] -left-[2px] h-14 w-[3px] rounded-l bg-ink" />
      <div className="absolute top-[140px] -right-[2px] h-16 w-[3px] rounded-r bg-ink" />
    </div>
  )
}
