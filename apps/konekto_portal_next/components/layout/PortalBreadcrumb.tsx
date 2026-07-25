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
    <div className="border-b border-border-strong px-8 py-5">
      <p className="text-[13px] text-slate">
        {hotelName}
        <span>{'  /  '}</span>
        <span className="font-bold text-cream">{section?.title ?? ''}</span>
      </p>
    </div>
  )
}
