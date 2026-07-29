import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useRooms } from './useRooms'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/rooms', () => ({ listRooms: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { listRooms } from '@/lib/api/rooms'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

describe('useRooms', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads rooms for the session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(listRooms).mockResolvedValue([])

    const { result } = renderHook(() => useRooms(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(listRooms).toHaveBeenCalledWith('h1', 'tok')
  })

  it('does not fetch without an authenticated session', () => {
    vi.mocked(useAuth).mockReturnValue({ session: null, token: null } as ReturnType<typeof useAuth>)
    renderHook(() => useRooms(), { wrapper })
    expect(listRooms).not.toHaveBeenCalled()
  })
})
