import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { OccupancyForm } from './OccupancyForm'

vi.mock('@/hooks/useGuests', () => ({ useGuestLookup: vi.fn(), useGuests: vi.fn() }))
vi.mock('@/hooks/useStays', () => ({ useStays: vi.fn() }))

import { useGuestLookup, useGuests } from '@/hooks/useGuests'
import { useStays } from '@/hooks/useStays'

const room = { id: 'r1', number: '101', description: null, activeStay: null }

function mockHooks({
  lookup = vi.fn(),
  createStay = vi.fn(),
  createGuest = vi.fn(),
}: {
  lookup?: ReturnType<typeof vi.fn>
  createStay?: ReturnType<typeof vi.fn>
  createGuest?: ReturnType<typeof vi.fn>
} = {}) {
  vi.mocked(useGuestLookup).mockReturnValue({ lookup, isLoading: false })
  vi.mocked(useGuests).mockReturnValue({
    guests: [],
    isLoading: false,
    error: null,
    createGuest,
    revokeGuest: vi.fn(),
  } as unknown as ReturnType<typeof useGuests>)
  vi.mocked(useStays).mockReturnValue({
    stays: [],
    isLoading: false,
    error: null,
    createStay,
  } as unknown as ReturnType<typeof useStays>)
  return { lookup, createStay, createGuest }
}

describe('OccupancyForm', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the free-room banner', () => {
    mockHooks()
    render(<OccupancyForm room={room} />)
    expect(screen.getByText('Este quarto está livre.')).toBeInTheDocument()
  })

  it('shows the not-found banner when lookup finds nothing', async () => {
    const { lookup } = mockHooks({ lookup: vi.fn().mockResolvedValue(null) })
    render(<OccupancyForm room={room} />)

    await userEvent.type(screen.getByLabelText('CPF'), '12345678900')
    await userEvent.click(screen.getByRole('button', { name: 'Buscar' }))

    expect(lookup).toHaveBeenCalledWith('12345678900')
    expect(
      await screen.findByText(/Nenhum cadastro encontrado com esse documento/),
    ).toBeInTheDocument()
  })

  it('prefills fields when lookup finds a returning guest', async () => {
    mockHooks({
      lookup: vi.fn().mockResolvedValue({
        firstName: 'Ana',
        lastName: 'Silva',
        documentType: 'cpf',
        documentNumber: '12345678900',
        phoneCountryCode: '+55',
        phoneNumber: '11999999999',
        whatsappCountryCode: null,
        whatsappNumber: null,
        email: 'ana@example.com',
        address: null,
        country: 'Brasil',
      }),
    })
    render(<OccupancyForm room={room} />)

    await userEvent.type(screen.getByLabelText('CPF'), '12345678900')
    await userEvent.click(screen.getByRole('button', { name: 'Buscar' }))

    expect(await screen.findByText(/Hóspede encontrado: Ana Silva/)).toBeInTheDocument()
    expect(screen.getByLabelText('Nome')).toHaveValue('Ana')
    expect(screen.getByLabelText('E-mail (opcional)')).toHaveValue('ana@example.com')
  })

  it('validates required fields before submitting', async () => {
    mockHooks()
    render(<OccupancyForm room={room} />)

    await userEvent.click(screen.getByRole('button', { name: /Registrar hóspede/ }))

    expect(
      await screen.findByText('Preencha as datas de check-in e check-out.'),
    ).toBeInTheDocument()
  })

  it('creates the stay then the guest and shows the access code dialog', async () => {
    const createStay = vi.fn().mockResolvedValue({ id: 's1' })
    const createGuest = vi.fn().mockResolvedValue({ accessCode: 'HOTEL1-XYZ' })
    mockHooks({ createStay, createGuest })
    const { container } = render(<OccupancyForm room={room} />)

    // Preenche muitos campos (incl. telefone char-a-char via userEvent) —
    // sob carga de toda a suíte em paralelo, o timeout default de 5s é
    // apertado; isolado o teste passa em ~1s.
    await userEvent.type(screen.getByLabelText('Check-in'), '2026-07-01')
    await userEvent.type(screen.getByLabelText('Check-out'), '2026-07-10')
    await userEvent.type(screen.getByLabelText('Nome'), 'Ana')
    await userEvent.type(screen.getByLabelText('Sobrenome'), 'Silva')
    await userEvent.type(screen.getByLabelText('CPF'), '12345678900')
    await userEvent.type(screen.getByLabelText('País'), 'Brasil')
    const phoneInput = container.querySelector('.PhoneInputInput') as HTMLInputElement
    await userEvent.type(phoneInput, '11999999999')

    await userEvent.click(screen.getByRole('button', { name: /Registrar hóspede/ }))

    await waitFor(() =>
      expect(createStay).toHaveBeenCalledWith({
        roomId: 'r1',
        checkInDate: '2026-07-01',
        checkOutDate: '2026-07-10',
      }),
    )
    await waitFor(() => expect(createGuest).toHaveBeenCalled())
    expect(createGuest.mock.calls[0][0]).toMatchObject({ stayId: 's1', firstName: 'Ana' })
    expect(await screen.findByRole('dialog', { name: 'Hóspede criado' })).toBeInTheDocument()
  }, 15000)
})
