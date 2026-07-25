import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useGuest, useGuests } from './useGuests'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/guests', () => ({
  listGuests: vi.fn(),
  getGuest: vi.fn(),
  createGuest: vi.fn(),
  updateGuest: vi.fn(),
  revokeGuest: vi.fn(),
  lookupGuestByDocument: vi.fn(),
}))

import { useAuth } from '@/lib/auth/AuthProvider'
import { getGuest, listGuests, revokeGuest } from '@/lib/api/guests'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

describe('useGuests', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads the guest list for the session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listGuests).mockResolvedValue([])

    const { result } = renderHook(() => useGuests(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(listGuests).toHaveBeenCalledWith('h1', 'tok')
  })

  it('revokeGuest calls the API with the guest id', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listGuests).mockResolvedValue([])
    vi.mocked(revokeGuest).mockResolvedValue(undefined)

    const { result } = renderHook(() => useGuests(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.revokeGuest('g1')

    expect(revokeGuest).toHaveBeenCalledWith('h1', 'g1', 'tok')
  })
})

describe('useGuest (detail)', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads a single guest by id', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(getGuest).mockResolvedValue({ id: 'g1', firstName: 'Ana' } as never)

    const { result } = renderHook(() => useGuest('g1'), { wrapper })

    await waitFor(() => expect(result.current.guest).not.toBeNull())
    expect(getGuest).toHaveBeenCalledWith('h1', 'g1', 'tok')
  })
})
