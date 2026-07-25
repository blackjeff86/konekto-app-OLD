import type { TopOrderItem } from '@/types/dashboardStats'

/** Portado de _TopItemsList (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function TopItemsList({ items }: { items: TopOrderItem[] }) {
  const maxTotal = Math.max(...items.map((item) => item.total))

  return (
    <div className="flex flex-col gap-2">
      {items.map((item) => (
        <div key={item.itemName} className="flex items-center gap-3 py-1.5">
          <span className="w-40 shrink-0 truncate text-[13px] text-cream">{item.itemName}</span>
          <div className="h-2 flex-1 overflow-hidden rounded-full bg-surface-alt">
            <div
              className="h-full rounded-full bg-gold"
              style={{ width: `${maxTotal > 0 ? (item.total / maxTotal) * 100 : 0}%` }}
            />
          </div>
          <span className="w-20 shrink-0 text-right text-[12.5px] font-semibold text-gold-light">
            R$ {item.total.toFixed(2)}
          </span>
        </div>
      ))}
    </div>
  )
}
