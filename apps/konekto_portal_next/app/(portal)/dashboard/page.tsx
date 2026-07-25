'use client'

import { KpiCard } from '@/components/dashboard/KpiCard'
import { SectionCard } from '@/components/dashboard/SectionCard'
import { RevenueTrendChart } from '@/components/dashboard/RevenueTrendChart'
import { OrdersStatusChart } from '@/components/dashboard/OrdersStatusChart'
import { CategoryRevenueChart } from '@/components/dashboard/CategoryRevenueChart'
import { TopItemsList } from '@/components/dashboard/TopItemsList'
import { UpcomingStaysList } from '@/components/dashboard/UpcomingStaysList'
import { useDashboardStats } from '@/hooks/useDashboardStats'

/**
 * Tela "Visão Geral" — portado de DashboardOverviewPage (apps/
 * konekto_portal/lib/features/dashboard/dashboard_overview_page.dart).
 * Primeira coisa que o staff vê ao entrar no portal: ocupação, receita,
 * funil de status dos pedidos, o que mais vende, e check-in/check-out dos
 * próximos dias — tudo de uma única chamada agregada.
 */
export default function DashboardPage() {
  const { stats, isLoading, error } = useDashboardStats()

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  if (!stats) {
    const message = error instanceof Error ? error.message : 'Não foi possível carregar.'
    return <p className="text-[13.5px] text-cream">{message}</p>
  }

  return (
    <div className="flex flex-col gap-8">
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          icon="🚪"
          label="Ocupação"
          value={`${(stats.occupancy.rate * 100).toFixed(0)}%`}
          detail={`${stats.occupancy.occupiedRooms} de ${stats.occupancy.totalRooms} quartos`}
        />
        <KpiCard
          icon="🧑‍🤝‍🧑"
          label="Hóspedes ativos"
          value={String(stats.activeGuests)}
          detail="com acesso ativo agora"
          className="lg:translate-y-6"
        />
        <KpiCard
          icon="📅"
          label="Receita hoje"
          value={`R$ ${stats.revenue.today.toFixed(2)}`}
          detail={`R$ ${stats.revenue.last7Days.toFixed(2)} nos últimos 7 dias`}
        />
        <KpiCard
          icon="💳"
          label="Receita 30 dias"
          value={`R$ ${stats.revenue.last30Days.toFixed(2)}`}
          detail={`ticket médio R$ ${stats.averageTicketPerGuest.toFixed(2)}/hóspede`}
          className="lg:translate-y-6"
        />
      </div>

      <SectionCard title="Receita nos últimos 14 dias">
        <RevenueTrendChart points={stats.revenueByDay} />
      </SectionCard>

      <div className="flex flex-col gap-5 lg:flex-row lg:items-start">
        <div className="flex-1">
          <SectionCard title="Pedidos por status (30 dias)">
            <OrdersStatusChart stats={stats.ordersByStatus} />
          </SectionCard>
        </div>
        <div className="flex-1">
          <SectionCard title="Receita por categoria (30 dias)">
            {stats.revenueByCategory.length === 0 ? (
              <div className="flex h-[220px] items-center justify-center">
                <p className="text-[13px] text-cream">Sem pedidos no período.</p>
              </div>
            ) : (
              <CategoryRevenueChart categories={stats.revenueByCategory} />
            )}
          </SectionCard>
        </div>
      </div>

      <SectionCard title="Itens mais pedidos (30 dias)">
        {stats.topItems.length === 0 ? (
          <p className="py-3 text-[13px] text-cream">Sem pedidos no período.</p>
        ) : (
          <TopItemsList items={stats.topItems} />
        )}
      </SectionCard>

      <div className="flex flex-col gap-5 lg:flex-row lg:items-start">
        <div className="flex-1">
          <SectionCard title="Chegadas nos próximos 7 dias">
            <UpcomingStaysList entries={stats.upcomingCheckIns} emptyLabel="Nenhuma chegada prevista." />
          </SectionCard>
        </div>
        <div className="flex-1">
          <SectionCard title="Saídas nos próximos 7 dias">
            <UpcomingStaysList entries={stats.upcomingCheckOuts} emptyLabel="Nenhuma saída prevista." />
          </SectionCard>
        </div>
      </div>
    </div>
  )
}
