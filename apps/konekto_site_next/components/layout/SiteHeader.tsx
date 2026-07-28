import Link from "next/link"
import { MAIN_NAVIGATION } from "@/content/navigation"
import { Logo } from "@/components/ui/Logo"

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-black/[0.08] bg-white/92 backdrop-blur-[10px]">
      <div className="mx-auto flex min-h-[76px] max-w-[1180px] items-center justify-between gap-4 px-8 py-4">
        <Logo />
        <ul className="hidden items-center gap-7 text-[14px] font-medium text-ink xl:flex">
          {MAIN_NAVIGATION.map((link) => (
            <li key={link.href}>
              <Link href={link.href} className="no-underline">
                {link.label}
              </Link>
            </li>
          ))}
        </ul>
        <div className="hidden items-center gap-[14px] sm:flex">
          <Link href="/login" className="text-[14px] font-semibold text-ink no-underline">
            Entrar
          </Link>
          <Link
            href="/contato#hotel-demo"
            className="rounded-[9px] bg-ink px-5 py-[11px] text-[14px] font-semibold text-white no-underline"
          >
            Agendar demonstração
          </Link>
        </div>
        <details className="xl:hidden">
          <summary className="list-none rounded-[10px] border border-border px-4 py-2 text-[0.92rem] font-semibold text-ink">
            Menu
          </summary>
          <div className="absolute right-8 top-[72px] w-[280px] rounded-[18px] border border-border bg-white p-4 shadow-[0_20px_60px_-38px_rgba(22,24,29,0.35)]">
            <nav className="flex flex-col gap-3">
              {MAIN_NAVIGATION.map((link) => (
                <Link key={link.href} href={link.href} className="text-[0.95rem] text-ink no-underline">
                  {link.label}
                </Link>
              ))}
              <div className="mt-3 flex flex-col gap-3 border-t border-border pt-3">
                <Link href="/login" className="text-[0.95rem] font-semibold text-ink no-underline">
                  Entrar
                </Link>
                <Link
                  href="/contato#hotel-demo"
                  className="rounded-[10px] bg-ink px-4 py-3 text-center text-[0.92rem] font-semibold text-white no-underline"
                >
                  Agendar demonstração
                </Link>
              </div>
            </nav>
          </div>
        </details>
      </div>
    </header>
  )
}
