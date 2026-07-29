import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { StayDetail } from './StayDetail'

vi.mock('@/hooks/useStay', () => ({ useStay: vi.fn() }))
vi.mock('@/hooks/useRooms', () => ({ useRooms: vi.fn() }))
vi.mock('@/hooks/useGuests', () => ({ useGuests: vi.fn(), useGuestLookup: vi.fn() }))
vi.mock('@/hooks/useMinibarItems', () => ({ useMinibarItems: vi.fn() }))

import { useGuestLookup, useGuests } from '@/hooks/useGuests'
import { useMinibarItems } from '@/hooks/useMinibarItems'
import { useRooms } from '@/hooks/useRooms'
import { useStay } from '@/hooks/useStay'

const baseStay = {
  id: 's1',
  roomNumber: '101',
  checkInDate: '2026-07-01T00:00:00.000Z',
  checkOutDate: '2026-07-10T00:00:00.000Z',
  status: 'active' as const,
  createdAt: '2026-07-01T00:00:00.000Z',
  guests: [
    {
      id: 'g1',
      firstName: 'Ana',
      lastName: 'Silva',
      accessCode: 'HOTEL1-ABC',
      status: 'active',
      orders: [
        {
          id: 'o1',
          itemName: 'Água',
          quantity: 2,
          price: 5,
          status: 'completed' as const,
          note: null,
          scheduledFor: null,
          createdAt: '2026-07-02T00:00:00.000Z',
          discountAmount: null,
          couponTitle: null,
          recordedByStaffId: null,
          partnerName: null,
          isPartnerPaid: false,
        },
        {
          id: 'o2',
          itemName: 'Refrigerante',
          quantity: 1,
          price: 8,
          status: 'cancelled' as const,
          note: null,
          scheduledFor: null,
          createdAt: '2026-07-02T00:00:00.000Z',
          discountAmount: null,
          couponTitle: null,
          recordedByStaffId: null,
          partnerName: null,
          isPartnerPaid: false,
        },
        {
          id: 'o3',
          itemName: 'Massagem',
          quantity: 1,
          price: 100,
          status: 'completed' as const,
          note: null,
          scheduledFor: null,
          createdAt: '2026-07-02T00:00:00.000Z',
          discountAmount: null,
          couponTitle: null,
          recordedByStaffId: null,
          partnerName: 'Spa Terceirizado',
          isPartnerPaid: true,
        },
      ],
    },
  ],
  notices: [],
  messages: [],
}

function mockHooks({
  stay = baseStay,
  extendStay = vi.fn(),
  changeRoom = vi.fn(),
  closeStay = vi.fn(),
  sendMessage = vi.fn(),
  recordConsumption = vi.fn(),
  rooms = [],
}: {
  stay?: typeof baseStay | null
  extendStay?: ReturnType<typeof vi.fn>
  changeRoom?: ReturnType<typeof vi.fn>
  closeStay?: ReturnType<typeof vi.fn>
  sendMessage?: ReturnType<typeof vi.fn>
  recordConsumption?: ReturnType<typeof vi.fn>
  rooms?: unknown[]
} = {}) {
  vi.mocked(useStay).mockReturnValue({
    stay,
    isLoading: false,
    error: null,
    extendStay,
    changeRoom,
    closeStay,
    sendMessage,
    recordConsumption,
  } as unknown as ReturnType<typeof useStay>)
  vi.mocked(useRooms).mockReturnValue({
    rooms,
    isLoading: false,
    error: null,
    refetch: vi.fn(),
  } as unknown as ReturnType<typeof useRooms>)
  vi.mocked(useGuests).mockReturnValue({
    guests: [],
    isLoading: false,
    error: null,
    createGuest: vi.fn(),
    revokeGuest: vi.fn(),
  } as unknown as ReturnType<typeof useGuests>)
  vi.mocked(useGuestLookup).mockReturnValue({ lookup: vi.fn(), isLoading: false })
  vi.mocked(useMinibarItems).mockReturnValue({
    minibarItems: [],
    isLoading: false,
    error: null,
  } as unknown as ReturnType<typeof useMinibarItems>)
  return { extendStay, changeRoom, closeStay, sendMessage, recordConsumption }
}

describe('StayDetail', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows dates, status and valor em aberto excluding cancelled and partner-paid orders', () => {
    mockHooks()
    render(<StayDetail stayId="s1" />)

    expect(screen.getByText('01/07/2026 até 10/07/2026')).toBeInTheDocument()
    expect(screen.getByText('Ativa')).toBeInTheDocument()
    // 5*2 (Água) = 10; Refrigerante (cancelled) and Massagem (partner-paid) excluded.
    expect(screen.getAllByText('R$ 10.00').length).toBeGreaterThan(0)
  })

  it('renders a guest row linking to its detail route', () => {
    mockHooks()
    render(<StayDetail stayId="s1" />)

    const link = screen.getByRole('link', { name: /Ana Silva/ })
    expect(link).toHaveAttribute('href', '/guests/g1')
  })

  it('lists all orders including cancelled/partner-paid with their tags', () => {
    mockHooks()
    render(<StayDetail stayId="s1" />)

    expect(screen.getByText('2x Água')).toBeInTheDocument()
    expect(screen.getByText('1x Refrigerante')).toBeInTheDocument()
    expect(screen.getByText(/Pago diretamente ao parceiro \(Spa Terceirizado\)/)).toBeInTheDocument()
  })

  it('sends a chat message', async () => {
    const { sendMessage } = mockHooks()
    sendMessage.mockResolvedValue(undefined)
    render(<StayDetail stayId="s1" />)

    await userEvent.type(
      screen.getByPlaceholderText(/seu jantar está pronto/),
      'Bom dia!',
    )
    await userEvent.click(screen.getByLabelText('Enviar mensagem'))

    await waitFor(() => expect(sendMessage).toHaveBeenCalledWith('Bom dia!'))
  })

  it('extends the stay with a new checkout date', async () => {
    const { extendStay } = mockHooks()
    extendStay.mockResolvedValue(undefined)
    render(<StayDetail stayId="s1" />)

    await userEvent.click(screen.getByText('Estender estadia'))
    const dialog = screen.getByRole('dialog', { name: 'Estender estadia' })
    const dateInput = within(dialog).getByLabelText('Nova data de saída')
    await userEvent.clear(dateInput)
    await userEvent.type(dateInput, '2026-07-15')
    await userEvent.click(within(dialog).getByRole('button', { name: 'Confirmar' }))

    await waitFor(() => expect(extendStay).toHaveBeenCalledWith('2026-07-15'))
  })

  it('changes the room via the free-room picker', async () => {
    const { changeRoom } = mockHooks({
      rooms: [
        { id: 'r2', number: '102', description: null, activeStay: null },
        { id: 'r1cur', number: '101', description: null, activeStay: { id: 's1' } },
      ],
    })
    changeRoom.mockResolvedValue(undefined)
    render(<StayDetail stayId="s1" />)

    await userEvent.click(screen.getByText('Trocar quarto'))
    const dialog = screen.getByRole('dialog', { name: 'Trocar quarto' })
    await userEvent.click(within(dialog).getByRole('button', { name: 'Mover' }))

    await waitFor(() => expect(changeRoom).toHaveBeenCalledWith('r2'))
  })

  it('closes the account after confirmation', async () => {
    const { closeStay } = mockHooks()
    closeStay.mockResolvedValue(undefined)
    render(<StayDetail stayId="s1" />)

    await userEvent.click(screen.getByText('Fechar conta'))
    const dialog = screen.getByRole('dialog', { name: 'Fechar conta do quarto 101?' })
    await userEvent.click(within(dialog).getByRole('button', { name: 'Fechar conta' }))

    await waitFor(() => expect(closeStay).toHaveBeenCalled())
  })

  it('launches a minibar consumption record', async () => {
    const { recordConsumption } = mockHooks()
    recordConsumption.mockResolvedValue(undefined)
    vi.mocked(useMinibarItems).mockReturnValue({
      minibarItems: [
        { service: { id: 'svc1', name: 'Serviço de Quarto' }, item: { id: 'i1', name: 'Água', price: 5, isMinibarItem: true } },
      ],
      isLoading: false,
      error: null,
    } as unknown as ReturnType<typeof useMinibarItems>)
    render(<StayDetail stayId="s1" />)

    await userEvent.click(screen.getByText('🧊 Lançar consumo'))
    const dialog = screen.getByRole('dialog', { name: 'Lançar consumo' })
    await userEvent.click(within(dialog).getByRole('button', { name: 'Lançar' }))

    await waitFor(() =>
      expect(recordConsumption).toHaveBeenCalledWith({ guestId: 'g1', serviceItemId: 'i1', quantity: 1 }),
    )
  })

  it('does not show action buttons when the stay is closed', () => {
    mockHooks({ stay: { ...baseStay, status: 'closed' } })
    render(<StayDetail stayId="s1" />)

    expect(screen.queryByText('Estender estadia')).not.toBeInTheDocument()
    expect(screen.queryByText('Fechar conta')).not.toBeInTheDocument()
    expect(screen.queryByText('+ Adicionar')).not.toBeInTheDocument()
  })
})
