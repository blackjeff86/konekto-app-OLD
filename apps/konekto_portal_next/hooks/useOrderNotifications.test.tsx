import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { act, renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useOrderNotifications } from './useOrderNotifications'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/orders', () => ({ listOrders: vi.fn() }))
vi.mock('@/lib/api/stays', () => ({ getUnreadMessagesCount: vi.fn() }))
vi.mock('@/lib/api/support', () => ({ listSupportMessages: vi.fn() }))
vi.mock('@/lib/browserNotifications', () => ({
  browserNotifications: { requestPermissionIfNeeded: vi.fn(), show: vi.fn() },
}))
vi.mock('@/lib/newOrderSound', () => ({ playNewOrderSound: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { listOrders } from '@/lib/api/orders'
import { getUnreadMessagesCount } from '@/lib/api/stays'
import { listSupportMessages } from '@/lib/api/support'
import { browserNotifications } from '@/lib/browserNotifications'
import { playNewOrderSound } from '@/lib/newOrderSound'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

const session = { uid: 'u1', hotelId: 'h1', role: 'gerente' as const, name: 'Ana', email: 'a@a.com' }

const order1 = {
  id: 'o1',
  itemName: 'Água',
  quantity: 1,
  price: 5,
  status: 'pending' as const,
  note: null,
  scheduledFor: null,
  guestName: 'Ana Silva',
  guestRoomNumber: '101',
  createdAt: '2026-07-01T00:00:00.000Z',
  discountAmount: null,
  couponTitle: null,
  recordedByStaffId: null,
  partnerName: null,
  isPartnerPaid: false,
}

describe('useOrderNotifications', () => {
  afterEach(() => vi.clearAllMocks())

  it('requests notification permission once on mount', () => {
    vi.mocked(useAuth).mockReturnValue({ session: null, token: null } as ReturnType<typeof useAuth>)
    vi.mocked(listOrders).mockResolvedValue([])
    vi.mocked(getUnreadMessagesCount).mockResolvedValue(0)
    vi.mocked(listSupportMessages).mockResolvedValue([])

    renderHook(() => useOrderNotifications(), { wrapper })

    expect(browserNotifications.requestPermissionIfNeeded).toHaveBeenCalledTimes(1)
  })

  it('does not notify for orders that already existed on the first load (seeding)', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listOrders).mockResolvedValue([order1])
    vi.mocked(getUnreadMessagesCount).mockResolvedValue(0)
    vi.mocked(listSupportMessages).mockResolvedValue([])

    renderHook(() => useOrderNotifications(), { wrapper })

    await waitFor(() => expect(listOrders).toHaveBeenCalled())
    expect(playNewOrderSound).not.toHaveBeenCalled()
    expect(browserNotifications.show).not.toHaveBeenCalled()
  })

  it('notifies when a genuinely new order appears after the list was already seeded', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(getUnreadMessagesCount).mockResolvedValue(0)
    vi.mocked(listSupportMessages).mockResolvedValue([])
    // Sempre [] — qualquer refetch automático do React Query (staleTime
    // padrão 0 dispara refetch ao montar) não deve introduzir o pedido
    // novo sozinho; só o setQueryData manual abaixo simula o próximo tick
    // do polling trazendo o pedido novo de verdade.
    vi.mocked(listOrders).mockResolvedValue([])

    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
    renderHook(() => useOrderNotifications(), {
      wrapper: ({ children }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>,
    })

    await waitFor(() => expect(client.getQueryData(['orders', 'h1'])).toEqual([]))
    // Simula o próximo tick do polling atualizando o cache diretamente.
    await act(async () => {
      client.setQueryData(['orders', 'h1'], [order1])
      await Promise.resolve()
    })

    await waitFor(() => expect(playNewOrderSound).toHaveBeenCalled())
    expect(browserNotifications.show).toHaveBeenCalledWith(
      expect.objectContaining({ title: 'Novo pedido' }),
    )
  })

  it('notifies when the unread guest-messages count increases after being seeded', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listOrders).mockResolvedValue([])
    vi.mocked(listSupportMessages).mockResolvedValue([])
    vi.mocked(getUnreadMessagesCount).mockResolvedValue(0)

    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
    renderHook(() => useOrderNotifications(), {
      wrapper: ({ children }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>,
    })

    await waitFor(() => expect(client.getQueryData(['unread-messages-count', 'h1'])).toBe(0))
    await act(async () => {
      client.setQueryData(['unread-messages-count', 'h1'], 1)
      await Promise.resolve()
    })

    await waitFor(() =>
      expect(browserNotifications.show).toHaveBeenCalledWith(
        expect.objectContaining({ title: 'Nova mensagem de hóspede' }),
      ),
    )
  })

  it('returns badge counts derived from orders/messages/support caches', async () => {
    vi.mocked(useAuth).mockReturnValue({ session, token: 'tok' } as ReturnType<typeof useAuth>)
    vi.mocked(listOrders).mockResolvedValue([
      order1,
      { ...order1, id: 'o2', status: 'completed' },
    ])
    vi.mocked(getUnreadMessagesCount).mockResolvedValue(2)
    vi.mocked(listSupportMessages).mockResolvedValue([
      { id: 'm1', senderType: 'platform', body: 'Oi', readByHotel: false, createdAt: '2026-07-01T00:00:00.000Z' },
      { id: 'm2', senderType: 'platform', body: 'Lido', readByHotel: true, createdAt: '2026-07-01T00:00:00.000Z' },
      { id: 'm3', senderType: 'hotel', body: 'Resposta', readByHotel: false, createdAt: '2026-07-01T00:00:00.000Z' },
    ])

    const { result } = renderHook(() => useOrderNotifications(), { wrapper })

    await waitFor(() =>
      expect(result.current).toEqual({
        pendingOrderCount: 1,
        unreadMessagesCount: 2,
        unreadSupportCount: 1,
      }),
    )
  })
})
