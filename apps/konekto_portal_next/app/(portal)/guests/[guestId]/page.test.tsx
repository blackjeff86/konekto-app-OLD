import { act, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Suspense } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import GuestDetailPage from './page'

vi.mock('@/hooks/useGuests', () => ({ useGuest: vi.fn() }))

import { useGuest } from '@/hooks/useGuests'

const baseGuest = {
  id: 'g1',
  firstName: 'Ana',
  lastName: 'Silva',
  documentType: 'cpf' as const,
  documentNumber: '12345678900',
  phoneCountryCode: '+55',
  phoneNumber: '11999999999',
  whatsappCountryCode: null,
  whatsappNumber: null,
  email: 'ana@example.com',
  address: null,
  country: 'Brasil',
  wifiPassword: null,
  accessCode: 'HOTEL1-ABC123',
  status: 'active' as const,
  createdAt: '2026-07-01T00:00:00.000Z',
  stay: {
    roomNumber: '101',
    checkInDate: '2026-07-01T00:00:00.000Z',
    checkOutDate: '2026-07-10T00:00:00.000Z',
    status: 'active' as const,
  },
  orders: [],
}

function mockUseGuest(overrides: Partial<ReturnType<typeof useGuest>> = {}) {
  vi.mocked(useGuest).mockReturnValue({
    guest: baseGuest,
    isLoading: false,
    error: null,
    updateGuest: vi.fn(),
    revokeGuest: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useGuest>)
}

async function renderPage() {
  const paramsPromise = Promise.resolve({ guestId: 'g1' })
  let utils: ReturnType<typeof render>
  await act(async () => {
    utils = render(
      <Suspense fallback={<div>carregando</div>}>
        <GuestDetailPage params={paramsPromise} />
      </Suspense>,
    )
  })
  return utils!
}

describe('GuestDetailPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('renders the guest cadastro details', async () => {
    mockUseGuest()
    await renderPage()

    expect(await screen.findByText('Ana Silva')).toBeInTheDocument()
    expect(screen.getByText(/CPF · 12345678900/)).toBeInTheDocument()
    expect(screen.getByText('101')).toBeInTheDocument()
    expect(screen.getByText('Ativo')).toBeInTheDocument()
  })

  it('shows an order line with staff-recorded and partner-paid tags', async () => {
    mockUseGuest({
      guest: {
        ...baseGuest,
        orders: [
          {
            id: 'o1',
            itemName: 'Água',
            quantity: 2,
            price: 5,
            status: 'completed',
            note: null,
            scheduledFor: null,
            createdAt: '2026-07-02T00:00:00.000Z',
            discountAmount: null,
            couponTitle: null,
            recordedByStaffId: 's1',
            partnerName: 'Spa Terceirizado',
            isPartnerPaid: true,
          },
        ],
      } as never,
    })
    await renderPage()

    expect(await screen.findByText('Água ×2')).toBeInTheDocument()
    expect(screen.getByText('R$ 10.00')).toBeInTheDocument()
    expect(screen.getByText('Lançado pela recepção')).toBeInTheDocument()
    expect(screen.getByText(/Pago diretamente ao parceiro \(Spa Terceirizado\)/)).toBeInTheDocument()
  })

  it('opens the edit dialog and submits via updateGuest', async () => {
    const updateGuest = vi.fn().mockResolvedValue(undefined)
    mockUseGuest({ updateGuest })
    await renderPage()

    await userEvent.click(await screen.findByLabelText('Editar cadastro'))
    const dialog = screen.getByRole('dialog', { name: 'Editar cadastro' })
    await userEvent.click(within(dialog).getByRole('button', { name: 'Salvar' }))

    await waitFor(() => expect(updateGuest).toHaveBeenCalled())
  })

  it('confirms and calls revokeGuest', async () => {
    const revokeGuest = vi.fn().mockResolvedValue(undefined)
    mockUseGuest({ revokeGuest })
    await renderPage()

    await userEvent.click(await screen.findByText('Revogar acesso'))
    const dialog = screen.getByRole('dialog', { name: 'Revogar acesso?' })
    await userEvent.click(within(dialog).getByRole('button', { name: 'Revogar' }))

    await waitFor(() => expect(revokeGuest).toHaveBeenCalled())
  })
})
