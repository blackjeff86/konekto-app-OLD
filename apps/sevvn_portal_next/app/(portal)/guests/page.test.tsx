import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import GuestsPage from './page'

vi.mock('@/hooks/useGuests', () => ({ useGuests: vi.fn() }))
vi.mock('@/hooks/useStays', () => ({ useStays: vi.fn() }))

import { useGuests } from '@/hooks/useGuests'
import { useStays } from '@/hooks/useStays'

const baseGuest = {
  id: 'g1',
  firstName: 'Ana',
  lastName: 'Silva',
  status: 'active' as const,
  accessCode: 'HOTEL1-ABC123',
  stay: { roomNumber: '101', checkInDate: '2026-07-01T00:00:00.000Z', checkOutDate: '2026-07-10T00:00:00.000Z', status: 'active' as const },
}

function mockUseGuests(overrides: Partial<ReturnType<typeof useGuests>> = {}) {
  vi.mocked(useGuests).mockReturnValue({
    guests: [],
    isLoading: false,
    error: null,
    createGuest: vi.fn(),
    revokeGuest: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useGuests>)
}

function mockUseStays(overrides: Partial<ReturnType<typeof useStays>> = {}) {
  vi.mocked(useStays).mockReturnValue({
    stays: [],
    isLoading: false,
    error: null,
    ...overrides,
  } as unknown as ReturnType<typeof useStays>)
}

describe('GuestsPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no guests', () => {
    mockUseGuests()
    mockUseStays()
    render(<GuestsPage />)
    expect(screen.getByText('Nenhum hóspede cadastrado ainda.')).toBeInTheDocument()
  })

  it('renders a row per guest linking to its detail route', () => {
    mockUseGuests({ guests: [baseGuest as never] })
    mockUseStays()
    render(<GuestsPage />)

    expect(screen.getByText('Ana Silva')).toBeInTheDocument()
    expect(screen.getByText(/Quarto 101/)).toBeInTheDocument()
    const link = screen.getByRole('link')
    expect(link).toHaveAttribute('href', '/guests/g1')
  })

  it('shows an error instead of opening the dialog when there are no active stays', async () => {
    mockUseGuests()
    mockUseStays({ stays: [] })
    render(<GuestsPage />)

    await userEvent.click(screen.getByText('+ Criar hóspede'))

    expect(
      screen.getByText(/Nenhum quarto ocupado ainda/),
    ).toBeInTheDocument()
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('opens the create dialog when there is at least one active stay', async () => {
    mockUseGuests()
    mockUseStays({
      stays: [
        { id: 's1', roomNumber: '101', status: 'active', guests: [], notices: [], messages: [], checkInDate: '', checkOutDate: '', createdAt: '' } as never,
      ],
    })
    render(<GuestsPage />)

    await userEvent.click(screen.getByText('+ Criar hóspede'))

    expect(screen.getByRole('dialog', { name: 'Criar hóspede' })).toBeInTheDocument()
  })
})
