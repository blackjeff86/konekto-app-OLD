import Link from "next/link"

const CURRENT_YEAR = new Date().getFullYear()

export function SiteFooter() {
  return (
    <footer className="border-t border-border py-10">
      <div className="mx-auto grid max-w-[1180px] grid-cols-1 gap-8 px-8 lg:grid-cols-[1fr_auto_1fr] lg:items-center">
        <div>
          <p className="text-[13px] text-muted">© {CURRENT_YEAR} Sevvn, Guest Experience Platform</p>
          <p className="mt-3 max-w-[320px] text-[13px] leading-[1.7] text-muted">
            Conectando hotéis, equipes, hóspedes, serviços e experiências em uma única jornada
            digital.
          </p>
        </div>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo/sevvn-lockup-footer.svg" alt="Sevvn" className="mx-auto h-14 w-auto" />
        <div className="flex flex-wrap items-center gap-4 lg:justify-end">
          <a href="mailto:contato@sevvn.app" className="text-[13px] text-muted no-underline">
            contato@sevvn.app
          </a>
          <Link href="/parceiros" className="text-[13px] text-muted no-underline">
            Parcerias
          </Link>
          <Link href="/login" className="text-[13px] text-muted no-underline">
            Entrar
          </Link>
        </div>
      </div>
    </footer>
  )
}
