import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useOrders } from './useOrders'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/orders', () => ({ listOrders: vi.fn(), updateOrderStatus: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { listOrders, updateOrderStatus } from '@/lib/api/orders'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

describe('useOrders', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads orders for the session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listOrders).mockResolvedValue([])

    const { result } = renderHook(() => useOrders(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(listOrders).toHaveBeenCalledWith('h1', 'tok')
  })

  it('updateStatus calls the API with orderId and status', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listOrders).mockResolvedValue([])
    vi.mocked(updateOrderStatus).mockResolvedValue(undefined)

    const { result } = renderHook(() => useOrders(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.updateStatus({ orderId: 'o1', status: 'in_progress' })

    expect(updateOrderStatus).toHaveBeenCalledWith('h1', 'o1', 'tok', 'in_progress')
  })
})
