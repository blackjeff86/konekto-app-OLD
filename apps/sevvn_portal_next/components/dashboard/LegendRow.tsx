/** Portado de _LegendRow (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function LegendRow({ color, label, value }: { color: string; label: string; value: string }) {
  return (
    <div className="flex items-center gap-2 py-1">
      <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: color }} />
      <span className="min-w-0 flex-1 truncate text-[12.5px] text-cream">{label}</span>
      <span className="shrink-0 text-[12.5px] font-semibold text-slate">{value}</span>
    </div>
  )
}
