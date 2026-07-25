'use client'

import { usePathname } from 'next/navigation'
import { useHotelConfig } from '@/hooks/useHotelConfig'
import { PORTAL_NAV_SECTIONS } from '@/lib/portalNav'

/** Portado de _Breadcrumb (apps/konekto_portal/lib/features/dashboard/dashboard_page.dart). */
export function PortalBreadcrumb() {
  const { config } = useHotelConfig()
  const pathname = usePathname()

  const section = PORTAL_NAV_SECTIONS.find((item) => pathname?.startsWith(item.matchPrefix))
  const hotelName = config?.hotelInfo?.name ?? '...'

  return (
    <div className="border-b border-border px-10 py-6">
      <p className="text-[11px] font-bold tracking-[0.2em] text-gold uppercase">{hotelName}</p>
      <h1 className="mt-1 text-2xl font-extrabold tracking-tight text-cream">{section?.title ?? ''}</h1>
    </div>
  )
}
