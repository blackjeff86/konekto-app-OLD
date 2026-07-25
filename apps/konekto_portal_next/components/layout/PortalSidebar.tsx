'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { KonektoMark } from '@/components/ui/KonektoMark'
import { useAuth } from '@/lib/auth/AuthProvider'
import { PORTAL_NAV_SECTIONS } from '@/lib/portalNav'
import { staffRoleLabel } from '@/types/staffSession'
import type { PortalBadgeCounts } from '@/hooks/useOrderNotifications'

/**
 * Rail lateral do portal — portado de PortalSidebar (apps/konekto_portal/
 * lib/features/dashboard/widgets/portal_sidebar.dart). Estado "ativo" vem
 * da URL (usePathname), não de um índice local — cada seção agora é uma
 * rota real.
 */
export function PortalSidebar({ badgeCounts }: { badgeCounts: PortalBadgeCounts }) {
  const { session, signOut } = useAuth()
  const pathname = usePathname()

  const sections = PORTAL_NAV_SECTIONS.filter(
    (section) => !section.gerenteOnly || session?.role === 'gerente',
  )

  return (
    <div className="flex w-[232px] shrink-0 flex-col border-r border-border-strong bg-surface">
      <div className="flex items-center gap-2.5 px-5 pb-6 pt-7">
        <KonektoMark size={26} />
        <div className="min-w-0">
          <p className="text-[15px] font-extrabold text-cream">Konekto</p>
          <p className="text-[9px] font-bold tracking-widest text-slate uppercase">Portal do hotel</p>
        </div>
      </div>
      <div className="border-t border-border-strong" />
      <nav className="flex flex-1 flex-col gap-1 py-3">
        {sections.map((section) => {
          const isActive = pathname?.startsWith(section.matchPrefix) ?? false
          const badgeCount = section.badgeKey ? badgeCounts[section.badgeKey] : 0
          return (
            <Link
              key={section.href}
              href={section.href}
              className="flex h-[46px] items-center gap-4 px-5"
            >
              <span
                className="h-[18px] w-0.5 shrink-0"
                style={{ backgroundColor: isActive ? 'var(--color-gold)' : 'transparent' }}
              />
              <span className="shrink-0 text-[15px]" aria-hidden>
                {section.icon}
              </span>
              <span
                className="min-w-0 flex-1 truncate text-[13.5px]"
                style={{
                  color: isActive ? 'var(--color-cream)' : 'var(--color-slate)',
                  fontWeight: isActive ? 700 : 500,
                }}
              >
                {section.title}
              </span>
              {badgeCount > 0 && (
                <span className="shrink-0 rounded-full bg-gold px-[7px] py-0.5 text-[10.5px] font-bold text-ink">
                  {badgeCount > 99 ? '99+' : badgeCount}
                </span>
              )}
            </Link>
          )
        })}
      </nav>
      <div className="border-t border-border-strong" />
      <div className="flex items-center gap-2 p-4">
        <div className="min-w-0 flex-1">
          <p className="truncate text-[12.5px] font-semibold text-cream">{session?.name}</p>
          <p className="text-[11px] text-gold-light">{session ? staffRoleLabel[session.role] : ''}</p>
        </div>
        <button type="button" aria-label="Sair" onClick={signOut} className="shrink-0 text-slate">
          ⏻
        </button>
      </div>
    </div>
  )
}
