import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useStay } from './useStay'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/stays', () => ({
  getStay: vi.fn(),
  markMessagesRead: vi.fn(),
  extendStay: vi.fn(),
  changeRoom: vi.fn(),
  closeStay: vi.fn(),
  sendMessage: vi.fn(),
}))
vi.mock('@/lib/api/orders', () => ({ recordConsumption: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { closeStay, getStay, markMessagesRead } from '@/lib/api/stays'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

describe('useStay', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads the stay and marks messages read as a side effect', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(getStay).mockResolvedValue({ id: 's1', roomNumber: '101' } as never)
    vi.mocked(markMessagesRead).mockResolvedValue(undefined)

    const { result } = renderHook(() => useStay('s1'), { wrapper })

    await waitFor(() => expect(result.current.stay).not.toBeNull())
    expect(getStay).toHaveBeenCalledWith('h1', 's1', 'tok')
    expect(markMessagesRead).toHaveBeenCalledWith('h1', 's1', 'tok')
  })

  it('closeStay calls the API with hotelId/stayId/token', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(getStay).mockResolvedValue({ id: 's1' } as never)
    vi.mocked(markMessagesRead).mockResolvedValue(undefined)
    vi.mocked(closeStay).mockResolvedValue(undefined)

    const { result } = renderHook(() => useStay('s1'), { wrapper })
    await waitFor(() => expect(result.current.stay).not.toBeNull())

    await result.current.closeStay()

    expect(closeStay).toHaveBeenCalledWith('h1', 's1', 'tok')
  })
})
