import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import CustomersPage from './page'

vi.mock('@/hooks/useCustomers', () => ({ useCustomers: vi.fn() }))

import { useCustomers } from '@/hooks/useCustomers'

const customerA = {
  documentType: 'cpf' as const,
  documentNumber: '111',
  firstName: 'Ana',
  lastName: 'Silva',
  email: 'ana@example.com',
  phoneCountryCode: '+55',
  phoneNumber: '11999999999',
  whatsappCountryCode: null,
  whatsappNumber: null,
  country: 'Brasil',
  visitsCount: 3,
  totalSpent: 450.5,
  firstVisit: '2026-01-01T00:00:00.000Z',
  lastVisit: '2026-07-01T00:00:00.000Z',
  stays: [],
}

const customerB = {
  ...customerA,
  documentNumber: '222',
  firstName: 'Bruno',
  lastName: 'Costa',
  visitsCount: 1,
  totalSpent: 100,
  lastVisit: '2026-06-01T00:00:00.000Z',
}

function mockUseCustomers(overrides: Partial<ReturnType<typeof useCustomers>> = {}) {
  vi.mocked(useCustomers).mockReturnValue({
    customers: [],
    isLoading: false,
    error: null,
    sendPromo: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useCustomers>)
}

describe('CustomersPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no customers', () => {
    mockUseCustomers()
    render(<CustomersPage />)
    expect(screen.getByText('Nenhum cliente no histórico ainda.')).toBeInTheDocument()
  })

  it('renders a row per customer sorted by last visit by default', () => {
    mockUseCustomers({ customers: [customerB, customerA] })
    render(<CustomersPage />)

    const rows = screen.getAllByRole('link')
    expect(rows[0]).toHaveTextContent('Ana Silva')
    expect(rows[1]).toHaveTextContent('Bruno Costa')
    expect(rows[0]).toHaveAttribute('href', '/customers/111')
  })

  it('filters by search query (name or document)', async () => {
    mockUseCustomers({ customers: [customerA, customerB] })
    render(<CustomersPage />)

    await userEvent.type(screen.getByPlaceholderText('Buscar por nome ou documento...'), 'Bruno')

    expect(screen.queryByText('Ana Silva')).not.toBeInTheDocument()
    expect(screen.getByText('Bruno Costa')).toBeInTheDocument()
  })
})
