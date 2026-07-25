import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useStays } from './useStays'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/stays', () => ({ listStays: vi.fn(), createStay: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { createStay, listStays } from '@/lib/api/stays'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

describe('useStays', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads stays for the session hotelId', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listStays).mockResolvedValue([])

    const { result } = renderHook(() => useStays(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(listStays).toHaveBeenCalledWith('h1', 'tok')
  })

  it('createStay calls the API with hotelId/token and the given input', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listStays).mockResolvedValue([])
    vi.mocked(createStay).mockResolvedValue({ id: 's1' } as never)

    const { result } = renderHook(() => useStays(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    const input = { roomId: 'r1', checkInDate: '2026-07-01', checkOutDate: '2026-07-10' }
    await result.current.createStay(input)

    expect(createStay).toHaveBeenCalledWith('h1', 'tok', input)
  })
})
