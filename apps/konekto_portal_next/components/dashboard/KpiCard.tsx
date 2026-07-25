/** Portado de _KpiCard (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
interface KpiCardProps {
  icon: string
  label: string
  value: string
  detail: string
}

export function KpiCard({ icon, label, value, detail }: KpiCardProps) {
  return (
    <div className="w-[240px] rounded-2xl border border-border-strong bg-surface p-[18px]">
      <div className="flex items-center gap-2">
        <span className="text-[15px] text-gold-light" aria-hidden>
          {icon}
        </span>
        <p className="text-[12.5px] text-slate">{label}</p>
      </div>
      <p className="mt-2.5 text-2xl font-bold text-cream">{value}</p>
      <p className="mt-1 text-[11.5px] text-slate-soft">{detail}</p>
    </div>
  )
}
