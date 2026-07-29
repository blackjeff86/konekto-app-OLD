import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useCustomers } from './useCustomers'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/customers', () => ({ listCustomers: vi.fn(), sendPromo: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { listCustomers, sendPromo } from '@/lib/api/customers'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

describe('useCustomers', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads customers for the session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listCustomers).mockResolvedValue([])

    const { result } = renderHook(() => useCustomers(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(listCustomers).toHaveBeenCalledWith('h1', 'tok')
  })

  it('sendPromo calls the API with hotelId/token plus the given args', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listCustomers).mockResolvedValue([])
    vi.mocked(sendPromo).mockResolvedValue(undefined)

    const { result } = renderHook(() => useCustomers(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.sendPromo({ documentNumber: '123', couponId: 'c1', message: 'Oi' })

    expect(sendPromo).toHaveBeenCalledWith('h1', '123', 'tok', 'c1', 'Oi')
  })
})
