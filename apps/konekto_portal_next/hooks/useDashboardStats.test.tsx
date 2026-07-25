import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useDashboardStats } from './useDashboardStats'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/dashboard', () => ({ getDashboardStats: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { getDashboardStats } from '@/lib/api/dashboard'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

describe('useDashboardStats', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads stats for the session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(getDashboardStats).mockResolvedValue({
      occupancy: { totalRooms: 10, occupiedRooms: 4, rate: 0.4 },
      activeGuests: 6,
      revenue: { today: 100, last7Days: 500, last30Days: 2000 },
      revenueByDay: [],
      ordersByStatus: { pending: 0, in_progress: 0, completed: 0, cancelled: 0 },
      revenueByCategory: [],
      topItems: [],
      averageTicketPerGuest: 50,
      upcomingCheckIns: [],
      upcomingCheckOuts: [],
    })

    const { result } = renderHook(() => useDashboardStats(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(getDashboardStats).toHaveBeenCalledWith('h1', 'tok')
    expect(result.current.stats?.activeGuests).toBe(6)
  })

  it('does not fetch without an authenticated session', () => {
    vi.mocked(useAuth).mockReturnValue({ session: null, token: null } as ReturnType<typeof useAuth>)
    renderHook(() => useDashboardStats(), { wrapper })
    expect(getDashboardStats).not.toHaveBeenCalled()
  })
})
