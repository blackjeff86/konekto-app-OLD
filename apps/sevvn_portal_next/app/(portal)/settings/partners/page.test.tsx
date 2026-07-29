import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import PartnersPage from './page'

vi.mock('@/hooks/usePartners', () => ({ usePartners: vi.fn() }))

import { usePartners } from '@/hooks/usePartners'

const basePartner = {
  id: 'p1',
  name: 'Spa Terceirizado',
  contactName: 'Maria',
  phone: '11999999999',
  email: null,
  notes: null,
}

function mockUsePartners(overrides: Partial<ReturnType<typeof usePartners>> = {}) {
  vi.mocked(usePartners).mockReturnValue({
    partners: [],
    isLoading: false,
    error: null,
    createPartner: vi.fn(),
    updatePartner: vi.fn(),
    deletePartner: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof usePartners>)
}

describe('PartnersPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no partners', () => {
    mockUsePartners()
    render(<PartnersPage />)
    expect(screen.getByText('Nenhum parceiro cadastrado ainda.')).toBeInTheDocument()
  })

  it('renders a row per partner with name and contact details', () => {
    mockUsePartners({ partners: [basePartner] })
    render(<PartnersPage />)

    expect(screen.getByText('Spa Terceirizado')).toBeInTheDocument()
    expect(screen.getByText(/Maria/)).toBeInTheDocument()
  })

  it('opens a confirmation modal and calls deletePartner on confirm', async () => {
    const deletePartner = vi.fn().mockResolvedValue(undefined)
    mockUsePartners({ partners: [basePartner], deletePartner })
    render(<PartnersPage />)

    await userEvent.click(screen.getByLabelText('Remover'))
    const dialog = screen.getByRole('dialog', { name: 'Remover parceiro?' })
    expect(within(dialog).getByText(/será removido permanentemente/)).toBeInTheDocument()

    await userEvent.click(within(dialog).getByRole('button', { name: 'Remover' }))

    await waitFor(() => expect(deletePartner).toHaveBeenCalledWith('p1'))
  })

  it('opens the create dialog when "Cadastrar parceiro" is clicked', async () => {
    mockUsePartners()
    render(<PartnersPage />)

    await userEvent.click(screen.getByText('+ Cadastrar parceiro'))

    expect(screen.getByRole('dialog', { name: 'Cadastrar parceiro' })).toBeInTheDocument()
  })
})
