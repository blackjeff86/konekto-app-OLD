import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { usePartners } from './usePartners'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/partners', () => ({
  listPartners: vi.fn(),
  createPartner: vi.fn(),
  updatePartner: vi.fn(),
  deletePartner: vi.fn(),
}))

import { useAuth } from '@/lib/auth/AuthProvider'
import { deletePartner, listPartners } from '@/lib/api/partners'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

describe('usePartners', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads partners for the current session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(listPartners).mockResolvedValue([
      { id: 'p1', name: 'Spa', contactName: null, phone: null, email: null, notes: null },
    ])

    const { result } = renderHook(() => usePartners(), { wrapper })

    await waitFor(() => expect(result.current.partners).toHaveLength(1))
    expect(listPartners).toHaveBeenCalledWith('h1', 'tok')
  })

  it('does not fetch without an authenticated session', () => {
    vi.mocked(useAuth).mockReturnValue({ session: null, token: null } as ReturnType<typeof useAuth>)
    renderHook(() => usePartners(), { wrapper })
    expect(listPartners).not.toHaveBeenCalled()
  })

  it('deletePartner calls the API and invalidates the list', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(listPartners).mockResolvedValue([])
    vi.mocked(deletePartner).mockResolvedValue(undefined)

    const { result } = renderHook(() => usePartners(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.deletePartner('p1')

    expect(deletePartner).toHaveBeenCalledWith('h1', 'p1', 'tok')
  })
})
