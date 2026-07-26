import Link from "next/link";
import { Logo } from "@/components/ui/Logo";

const NAV_LINKS = [
  { href: "#plataforma", label: "Plataforma" },
  { href: "#templates", label: "Templates" },
  { href: "#modulos", label: "Módulos" },
  { href: "#planos", label: "Planos" },
  { href: "#faq", label: "FAQ" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-black/[0.08] bg-white/92 backdrop-blur-[10px]">
      <div className="mx-auto flex h-[76px] max-w-[1180px] items-center justify-between px-8">
        <Logo />
        <ul className="hidden items-center gap-9 text-[14px] font-medium text-ink lg:flex">
          {NAV_LINKS.map((link) => (
            <li key={link.href}>
              <a href={link.href} className="no-underline">
                {link.label}
              </a>
            </li>
          ))}
        </ul>
        <div className="flex items-center gap-[14px]">
          <Link href="/login" className="text-[14px] font-semibold text-ink no-underline">
            Entrar
          </Link>
          <a
            href="#planos"
            className="rounded-[9px] bg-ink px-5 py-[11px] text-[14px] font-semibold text-white no-underline"
          >
            Agendar demo
          </a>
        </div>
      </div>
    </header>
  );
}
