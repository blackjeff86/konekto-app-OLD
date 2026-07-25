import type { ReactNode } from 'react'

/** Portado de _SectionCard (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function SectionCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="w-full rounded-2xl border border-border-strong bg-surface p-5">
      <h2 className="text-[15px] font-bold text-cream">{title}</h2>
      <div className="mt-4">{children}</div>
    </div>
  )
}
