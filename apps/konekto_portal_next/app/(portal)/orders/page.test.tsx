import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import OrdersPage from './page'

vi.mock('@/hooks/useOrders', () => ({ useOrders: vi.fn() }))

import { useOrders } from '@/hooks/useOrders'

const baseOrder = {
  id: 'o1',
  itemName: 'Água',
  quantity: 2,
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

function mockUseOrders(overrides: Partial<ReturnType<typeof useOrders>> = {}) {
  vi.mocked(useOrders).mockReturnValue({
    orders: [],
    isLoading: false,
    error: null,
    updateStatus: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useOrders>)
}

describe('OrdersPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no orders', () => {
    mockUseOrders()
    render(<OrdersPage />)
    expect(screen.getByText('Nenhum pedido ainda.')).toBeInTheDocument()
  })

  it('renders an order row with item, guest, room and price', () => {
    mockUseOrders({ orders: [baseOrder] })
    render(<OrdersPage />)

    expect(screen.getByText('Água ×2')).toBeInTheDocument()
    expect(screen.getByText(/Ana Silva · Quarto 101/)).toBeInTheDocument()
    expect(screen.getByText('Pendente')).toBeInTheDocument()
  })

  it('shows a status-change select for a pending order and calls updateStatus', async () => {
    const updateStatus = vi.fn()
    mockUseOrders({ orders: [baseOrder], updateStatus })
    render(<OrdersPage />)

    const select = screen.getByLabelText('Mudar status de Água')
    await userEvent.selectOptions(select, 'in_progress')

    expect(updateStatus).toHaveBeenCalledWith({ orderId: 'o1', status: 'in_progress' })
  })

  it('does not show a status-change select for a completed order', () => {
    mockUseOrders({ orders: [{ ...baseOrder, status: 'completed' }] })
    render(<OrdersPage />)

    expect(screen.queryByLabelText('Mudar status de Água')).not.toBeInTheDocument()
  })
})
