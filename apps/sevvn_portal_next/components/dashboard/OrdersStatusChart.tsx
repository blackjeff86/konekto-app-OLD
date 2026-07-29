'use client'

import { Cell, Pie, PieChart, ResponsiveContainer } from 'recharts'
import { LegendRow } from './LegendRow'
import { ordersByStatusTotal, type OrdersByStatus } from '@/types/dashboardStats'

const STATUS_META: { key: keyof OrdersByStatus; label: string; color: string }[] = [
  { key: 'pending', label: 'Pendente', color: '#B6005B' },
  { key: 'in_progress', label: 'Em andamento', color: '#7CA9C9' },
  { key: 'completed', label: 'Concluído', color: '#8FBF8A' },
  { key: 'cancelled', label: 'Cancelado', color: '#C98A8A' },
]

/** Portado de _OrdersStatusChart (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function OrdersStatusChart({ stats }: { stats: OrdersByStatus }) {
  if (ordersByStatusTotal(stats) === 0) {
    return (
      <div className="flex h-[220px] items-center justify-center">
        <p className="text-[13px] text-cream">Sem pedidos no período.</p>
      </div>
    )
  }

  const entries = STATUS_META.map((meta) => ({ ...meta, value: stats[meta.key] })).filter(
    (entry) => entry.value > 0,
  )

  return (
    <div className="flex h-[220px] items-center gap-5">
      <div className="h-[140px] w-[140px] shrink-0">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={entries} dataKey="value" nameKey="label" innerRadius={36} outerRadius={68} paddingAngle={2}>
              {entries.map((entry) => (
                <Cell key={entry.key} fill={entry.color} />
              ))}
            </Pie>
          </PieChart>
        </ResponsiveContainer>
      </div>
      <div className="min-w-0 flex-1">
        {entries.map((entry) => (
          <LegendRow key={entry.key} color={entry.color} label={entry.label} value={String(entry.value)} />
        ))}
      </div>
    </div>
  )
}
