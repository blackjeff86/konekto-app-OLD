/** Portado de _KpiCard (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
interface KpiCardProps {
  icon: string
  label: string
  value: string
  detail: string
}

export function KpiCard({ icon, label, value, detail }: KpiCardProps) {
  return (
    <div className="whisper-shadow flex h-[168px] flex-col justify-between rounded-xl border border-border bg-surface p-6">
      <div className="flex items-center gap-2">
        <span className="text-[15px] text-gold" aria-hidden>
          {icon}
        </span>
        <p className="text-[10.5px] font-bold tracking-[0.14em] text-slate uppercase">{label}</p>
      </div>
      <div>
        <p className="text-3xl font-extrabold tracking-tight text-cream">{value}</p>
        <p className="mt-1.5 text-[11.5px] text-slate-soft">{detail}</p>
      </div>
    </div>
  )
}
