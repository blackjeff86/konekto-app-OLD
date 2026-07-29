import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import DashboardPage from './page'

vi.mock('@/hooks/useDashboardStats', () => ({ useDashboardStats: vi.fn() }))

import { useDashboardStats } from '@/hooks/useDashboardStats'

const baseStats = {
  occupancy: { totalRooms: 10, occupiedRooms: 4, rate: 0.4 },
  activeGuests: 6,
  revenue: { today: 100, last7Days: 500, last30Days: 2000 },
  revenueByDay: [
    { date: '2026-07-01T00:00:00.000Z', total: 100 },
    { date: '2026-07-02T00:00:00.000Z', total: 200 },
  ],
  ordersByStatus: { pending: 1, in_progress: 2, completed: 3, cancelled: 0 },
  revenueByCategory: [{ category: 'Restaurante', total: 300 }],
  topItems: [{ itemName: 'Água', quantity: 10, total: 50 }],
  averageTicketPerGuest: 33.5,
  upcomingCheckIns: [{ stayId: 's1', roomNumber: '101', date: '2026-07-05T00:00:00.000Z', guestNames: ['Ana'] }],
  upcomingCheckOuts: [],
}

function mockStats(overrides: Partial<ReturnType<typeof useDashboardStats>> = {}) {
  vi.mocked(useDashboardStats).mockReturnValue({
    stats: baseStats,
    isLoading: false,
    error: null,
    refetch: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useDashboardStats>)
}

describe('DashboardPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('renders KPI values from stats', () => {
    mockStats()
    render(<DashboardPage />)

    expect(screen.getByText('40%')).toBeInTheDocument()
    expect(screen.getByText('4 de 10 quartos')).toBeInTheDocument()
    expect(screen.getByText('6')).toBeInTheDocument()
    expect(screen.getByText('R$ 100.00')).toBeInTheDocument()
    expect(screen.getByText('R$ 2000.00')).toBeInTheDocument()
  })

  it('shows the empty state for top items when there are none', () => {
    mockStats({ stats: { ...baseStats, topItems: [] } } as never)
    render(<DashboardPage />)
    expect(screen.getByText('Sem pedidos no período.')).toBeInTheDocument()
  })

  it('shows the empty label for upcoming check-outs', () => {
    mockStats()
    render(<DashboardPage />)
    expect(screen.getByText('Nenhuma saída prevista.')).toBeInTheDocument()
  })

  it('renders a loading spinner while stats are loading', () => {
    mockStats({ isLoading: true, stats: null } as never)
    render(<DashboardPage />)
    expect(screen.queryByText('40%')).not.toBeInTheDocument()
  })
})
