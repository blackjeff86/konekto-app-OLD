import { BRAND } from "@/content/brand"
import { Badge } from "@/components/ui/Badge"

const PLATFORM_POINTS = [
  "Aplicativo do hóspede White Label",
  "Portal operacional do hotel",
  "Integrações PMS e sistemas",
  "Rede de parceiros em desenvolvimento",
] as const

export function Hero() {
  return (
    <header className="overflow-hidden border-b border-border bg-[radial-gradient(circle_at_top,#fff0f7_0%,#ffffff_36%,#fafaf9_100%)] pb-20 pt-18 sm:pb-24 sm:pt-24">
      <div className="mx-auto grid max-w-[1180px] gap-12 px-8 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
        <div>
          <Badge>Guest Experience Platform</Badge>
          <h1 className="mt-6 max-w-[760px] text-[clamp(2.8rem,7vw,5.3rem)] font-extrabold leading-[0.98] tracking-[-0.055em] text-ink">
            {BRAND.heroHeadline}
          </h1>
          <p className="mt-6 max-w-[680px] text-[1.06rem] leading-[1.8] text-muted">
            {BRAND.heroSubheadline}
          </p>
          <div className="mt-9 flex flex-wrap gap-3">
            <a
              href="/contato#hotel-demo"
              className="rounded-[12px] bg-primary px-6 py-[0.95rem] text-[0.95rem] font-bold text-white no-underline"
            >
              {BRAND.primaryCtaLabel}
            </a>
            <a
              href="/plataforma"
              className="rounded-[12px] border border-border-strong bg-white px-6 py-[0.95rem] text-[0.95rem] font-bold text-ink no-underline"
            >
              {BRAND.secondaryCtaLabel}
            </a>
            <a
              href="/parceiros"
              className="rounded-[12px] px-4 py-[0.95rem] text-[0.92rem] font-semibold text-ink no-underline"
            >
              {BRAND.partnerCtaLabel}
            </a>
          </div>
        </div>

        <div className="relative">
          <div className="absolute -left-6 top-12 h-24 w-24 rounded-full bg-primary/10 blur-2xl" />
          <div className="absolute right-0 top-0 h-20 w-20 rounded-full bg-[#16181d]/6 blur-2xl" />
          <div className="relative rounded-[32px] border border-border bg-white p-6 shadow-[0_42px_90px_-48px_rgba(22,24,29,0.3)]">
            <div className="rounded-[24px] bg-ink px-5 py-5 text-white">
              <p className="text-[0.74rem] font-bold uppercase tracking-[0.2em] text-primary">Sevvn Platform</p>
              <div className="mt-5 grid gap-3 sm:grid-cols-2">
                {PLATFORM_POINTS.map((point) => (
                  <div key={point} className="rounded-[16px] border border-white/10 bg-white/[0.04] px-4 py-4 text-[0.92rem] text-white/85">
                    {point}
                  </div>
                ))}
              </div>
            </div>
            <div className="mt-5 grid gap-3 md:grid-cols-3">
              <InfoCard title="Hotel" copy="Configura operação, módulos, serviços e integrações." />
              <InfoCard title="Equipe" copy="Atende, opera pedidos, reservas e comunicação." />
              <InfoCard title="Hóspede" copy="Vive a experiência visível da plataforma." />
            </div>
          </div>
        </div>
      </div>
    </header>
  )
}

function InfoCard({ title, copy }: { title: string; copy: string }) {
  return (
    <div className="rounded-[18px] border border-border bg-surface-alt p-4">
      <p className="text-[0.84rem] font-bold uppercase tracking-[0.14em] text-primary">{title}</p>
      <p className="mt-2 text-[0.86rem] leading-[1.65] text-muted">{copy}</p>
    </div>
  )
}
