import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import RoomsPage from './page'

vi.mock('@/hooks/useRooms', () => ({ useRooms: vi.fn() }))

import { useRooms } from '@/hooks/useRooms'

const freeRoom = { id: 'r1', number: '101', description: 'Vista mar', activeStay: null }
const occupiedRoom = {
  id: 'r2',
  number: '102',
  description: null,
  activeStay: {
    id: 's1',
    checkInDate: '2026-07-01T00:00:00.000Z',
    checkOutDate: '2026-07-10T00:00:00.000Z',
    guestCount: 2,
    consumptionTotal: 45.5,
  },
}

function mockUseRooms(overrides: Partial<ReturnType<typeof useRooms>> = {}) {
  vi.mocked(useRooms).mockReturnValue({
    rooms: [],
    isLoading: false,
    error: null,
    refetch: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useRooms>)
}

describe('RoomsPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no rooms', () => {
    mockUseRooms()
    render(<RoomsPage />)
    expect(screen.getByText(/Nenhum quarto cadastrado ainda/)).toBeInTheDocument()
  })

  it('splits rooms into free and occupied sections', () => {
    mockUseRooms({ rooms: [freeRoom, occupiedRoom] })
    render(<RoomsPage />)

    expect(screen.getByText('Quarto 101')).toBeInTheDocument()
    expect(screen.getByText('Quarto 102')).toBeInTheDocument()
    expect(screen.getByText('Livre')).toBeInTheDocument()
    expect(screen.getByText('Ocupado')).toBeInTheDocument()
    expect(screen.getByText('2 hóspedes')).toBeInTheDocument()
    expect(screen.getByText('R$ 45.50')).toBeInTheDocument()
  })

  it('links each room card to its detail route', () => {
    mockUseRooms({ rooms: [freeRoom] })
    render(<RoomsPage />)

    expect(screen.getByRole('link', { name: /Quarto 101/ })).toHaveAttribute('href', '/rooms/r1')
  })
})
