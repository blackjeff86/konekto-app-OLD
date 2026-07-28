'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { SevvnMark } from '@/components/ui/KonektoMark'
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
    <div className="sticky top-0 flex h-screen w-64 shrink-0 flex-col overflow-y-auto border-r border-border bg-surface px-4 py-8">
      <div className="mb-10 flex items-center gap-2.5 px-2">
        <SevvnMark size={26} />
        <div className="min-w-0">
          <p className="text-base font-extrabold tracking-tight text-cream">Sevvn</p>
          <p className="text-[10px] font-bold tracking-[0.2em] text-slate-soft uppercase">Hotel Console</p>
        </div>
      </div>
      <nav className="flex flex-1 flex-col gap-1">
        {sections.map((section) => {
          const isActive = pathname?.startsWith(section.matchPrefix) ?? false
          const badgeCount = section.badgeKey ? badgeCounts[section.badgeKey] : 0
          return (
            <Link
              key={section.href}
              href={section.href}
              className="flex items-center gap-3 rounded-lg px-4 py-3 transition-colors"
              style={{ backgroundColor: isActive ? 'rgba(255,46,136,0.06)' : 'transparent' }}
            >
              <span className="shrink-0 text-base" aria-hidden>
                {section.icon}
              </span>
              <span
                className="min-w-0 flex-1 truncate text-[13.5px]"
                style={{
                  color: isActive ? 'var(--color-gold-light)' : 'var(--color-slate)',
                  fontWeight: isActive ? 700 : 500,
                }}
              >
                {section.title}
              </span>
              {badgeCount > 0 && (
                <span className="shrink-0 rounded-full bg-gold px-[7px] py-0.5 text-[10.5px] font-bold text-white">
                  {badgeCount > 99 ? '99+' : badgeCount}
                </span>
              )}
            </Link>
          )
        })}
      </nav>
      <div className="mt-auto flex items-center gap-2 rounded-lg bg-surface-alt p-3">
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
