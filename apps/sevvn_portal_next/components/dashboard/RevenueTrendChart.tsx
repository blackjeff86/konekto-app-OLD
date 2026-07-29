'use client'

import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis } from 'recharts'
import { formatShortDate } from '@/lib/utils/date'
import type { RevenueDayPoint } from '@/types/dashboardStats'

/** Portado de _RevenueTrendChart (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function RevenueTrendChart({ points }: { points: RevenueDayPoint[] }) {
  if (points.every((point) => point.total === 0)) {
    return (
      <div className="flex h-[220px] items-center justify-center">
        <p className="text-[13px] text-cream">Sem receita registrada no período.</p>
      </div>
    )
  }

  const data = points.map((point) => ({ ...point, label: formatShortDate(point.date) }))

  return (
    <div className="h-[220px]">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 0 }}>
          <CartesianGrid vertical={false} stroke="var(--color-border-strong)" />
          <XAxis
            dataKey="label"
            tick={{ fontSize: 10.5, fill: 'var(--color-slate)' }}
            axisLine={false}
            tickLine={false}
            interval="preserveStartEnd"
          />
          <Tooltip
            cursor={{ fill: 'rgba(22,24,29,0.04)' }}
            contentStyle={{
              background: 'var(--color-surface-alt)',
              border: 'none',
              borderRadius: 8,
              fontSize: 12,
              color: 'var(--color-cream)',
            }}
            formatter={(value) => [`R$ ${Number(value).toFixed(2)}`, 'Receita']}
          />
          <Bar dataKey="total" fill="var(--color-gold)" radius={[4, 4, 0, 0]} maxBarSize={14} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
