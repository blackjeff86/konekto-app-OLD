import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useSupport } from './useSupport'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/support', () => ({
  listSupportMessages: vi.fn(),
  sendSupportMessage: vi.fn(),
  markSupportMessagesRead: vi.fn(),
}))

import { useAuth } from '@/lib/auth/AuthProvider'
import { listSupportMessages, markSupportMessagesRead, sendSupportMessage } from '@/lib/api/support'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

describe('useSupport', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads messages and marks them read as a side effect', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listSupportMessages).mockResolvedValue([])
    vi.mocked(markSupportMessagesRead).mockResolvedValue(undefined)

    const { result } = renderHook(() => useSupport(), { wrapper })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(listSupportMessages).toHaveBeenCalledWith('h1', 'tok')
    expect(markSupportMessagesRead).toHaveBeenCalledWith('h1', 'tok')
  })

  it('sendMessage calls the API and invalidates the list', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listSupportMessages).mockResolvedValue([])
    vi.mocked(markSupportMessagesRead).mockResolvedValue(undefined)
    vi.mocked(sendSupportMessage).mockResolvedValue(undefined)

    const { result } = renderHook(() => useSupport(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.sendMessage('Oi, preciso de ajuda')

    expect(sendSupportMessage).toHaveBeenCalledWith('h1', 'tok', 'Oi, preciso de ajuda')
  })
})
