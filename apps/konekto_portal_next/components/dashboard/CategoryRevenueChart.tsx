'use client'

import { Cell, Pie, PieChart, ResponsiveContainer } from 'recharts'
import { LegendRow } from './LegendRow'
import type { CategoryRevenue } from '@/types/dashboardStats'

const CATEGORY_PALETTE = ['#FF2E88', '#7CA9C9', '#8FBF8A', '#C98A8A', '#C9A6E8', '#E0B589']

/** Portado de _CategoryRevenueChart (apps/konekto_portal/lib/features/dashboard/dashboard_overview_page.dart). */
export function CategoryRevenueChart({ categories }: { categories: CategoryRevenue[] }) {
  const top = categories.slice(0, CATEGORY_PALETTE.length)

  return (
    <div className="flex h-[220px] items-center gap-5">
      <div className="h-[140px] w-[140px] shrink-0">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={top} dataKey="total" nameKey="category" innerRadius={36} outerRadius={68} paddingAngle={2}>
              {top.map((category, index) => (
                <Cell key={category.category} fill={CATEGORY_PALETTE[index % CATEGORY_PALETTE.length]} />
              ))}
            </Pie>
          </PieChart>
        </ResponsiveContainer>
      </div>
      <div className="min-w-0 flex-1">
        {top.map((category, index) => (
          <LegendRow
            key={category.category}
            color={CATEGORY_PALETTE[index % CATEGORY_PALETTE.length]}
            label={category.category}
            value={`R$ ${category.total.toFixed(2)}`}
          />
        ))}
      </div>
    </div>
  )
}
