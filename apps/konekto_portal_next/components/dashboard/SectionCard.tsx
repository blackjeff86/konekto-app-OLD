import type { ReactNode } from 'react'

/** Portado de _SectionCard (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function SectionCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="whisper-shadow w-full rounded-xl border border-border bg-surface p-7">
      <h2 className="text-[11px] font-bold tracking-[0.14em] text-slate uppercase">{title}</h2>
      <div className="mt-5">{children}</div>
    </div>
  )
}
