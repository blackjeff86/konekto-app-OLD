import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import RoomRegistryPage from './page'

vi.mock('@/hooks/useRooms', () => ({ useRooms: vi.fn() }))

import { useRooms } from '@/hooks/useRooms'

const baseRoom = {
  id: 'r1',
  number: '101',
  description: 'Suíte com vista pro mar',
  activeStay: null,
}

function mockUseRooms(overrides: Partial<ReturnType<typeof useRooms>> = {}) {
  vi.mocked(useRooms).mockReturnValue({
    rooms: [],
    isLoading: false,
    error: null,
    refetch: vi.fn(),
    createRoom: vi.fn(),
    updateRoom: vi.fn(),
    deleteRoom: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useRooms>)
}

describe('RoomRegistryPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no rooms', () => {
    mockUseRooms()
    render(<RoomRegistryPage />)
    expect(screen.getByText('Nenhum quarto cadastrado ainda.')).toBeInTheDocument()
  })

  it('renders a row per room with number, description and free/occupied badge', () => {
    mockUseRooms({ rooms: [baseRoom] })
    render(<RoomRegistryPage />)

    expect(screen.getByText('Quarto 101')).toBeInTheDocument()
    expect(screen.getByText('Suíte com vista pro mar')).toBeInTheDocument()
    expect(screen.getByText('Livre')).toBeInTheDocument()
  })

  it('shows "Ocupado" for a room with an active stay', () => {
    mockUseRooms({
      rooms: [{ ...baseRoom, activeStay: { id: 's1', checkInDate: '', checkOutDate: '', guestCount: 1, consumptionTotal: 0 } }],
    })
    render(<RoomRegistryPage />)
    expect(screen.getByText('Ocupado')).toBeInTheDocument()
  })

  it('opens a confirmation modal and calls deleteRoom on confirm', async () => {
    const deleteRoom = vi.fn().mockResolvedValue(undefined)
    mockUseRooms({ rooms: [baseRoom], deleteRoom })
    render(<RoomRegistryPage />)

    await userEvent.click(screen.getByLabelText('Remover'))
    const dialog = screen.getByRole('dialog', { name: 'Remover quarto?' })
    expect(within(dialog).getByText(/será removido permanentemente/)).toBeInTheDocument()

    await userEvent.click(within(dialog).getByRole('button', { name: 'Remover' }))

    await waitFor(() => expect(deleteRoom).toHaveBeenCalledWith('r1'))
  })

  it('opens the create dialog when "Cadastrar quarto" is clicked', async () => {
    mockUseRooms()
    render(<RoomRegistryPage />)

    await userEvent.click(screen.getByText('+ Cadastrar quarto'))

    expect(screen.getByRole('dialog', { name: 'Cadastrar quarto' })).toBeInTheDocument()
  })

  it('submits the create form with trimmed values', async () => {
    const createRoom = vi.fn().mockResolvedValue(undefined)
    mockUseRooms({ createRoom })
    render(<RoomRegistryPage />)

    await userEvent.click(screen.getByText('+ Cadastrar quarto'))
    await userEvent.type(screen.getByLabelText('Número do quarto'), '202')
    await userEvent.click(screen.getByRole('button', { name: 'Salvar' }))

    await waitFor(() => expect(createRoom).toHaveBeenCalledWith({ number: '202', description: null }))
  })
})
