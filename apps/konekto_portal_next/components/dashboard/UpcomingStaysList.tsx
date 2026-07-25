import { formatShortDate } from '@/lib/utils/date'
import type { UpcomingStayEntry } from '@/types/dashboardStats'

/** Portado de _UpcomingStaysList (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function UpcomingStaysList({ entries, emptyLabel }: { entries: UpcomingStayEntry[]; emptyLabel: string }) {
  if (entries.length === 0) {
    return <p className="py-3 text-[13px] text-cream">{emptyLabel}</p>
  }

  return (
    <div className="divide-y divide-border-strong">
      {entries.map((entry) => (
        <div key={entry.stayId} className="flex items-center gap-3 py-2">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[10px] bg-gold/[0.12]">
            <span className="text-xs font-bold text-gold-light">{entry.roomNumber}</span>
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-[13px] text-cream">
              {entry.guestNames.length === 0 ? 'Sem hóspede' : entry.guestNames.join(', ')}
            </p>
            <p className="text-[11.5px] text-slate">{formatShortDate(entry.date)}</p>
          </div>
        </div>
      ))}
    </div>
  )
}
