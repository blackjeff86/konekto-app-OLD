import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import CouponsPage from './page'

vi.mock('@/hooks/useCoupons', () => ({ useCoupons: vi.fn() }))
vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))

import { useCoupons } from '@/hooks/useCoupons'
import { useAuth } from '@/lib/auth/AuthProvider'

const baseCoupon = {
  id: 'c1',
  title: 'Desconto verão',
  description: 'Promo',
  code: 'VERAO10',
  discountType: 'percentage' as const,
  discountValue: 10,
  minOrderValue: 50,
  imageUrl: null,
  validFrom: null,
  validUntil: '2026-12-31T00:00:00.000Z',
  usageLimit: null,
  perGuestLimit: 1,
  enabled: true,
}

function mockUseCoupons(overrides: Partial<ReturnType<typeof useCoupons>> = {}) {
  vi.mocked(useCoupons).mockReturnValue({
    coupons: [],
    isLoading: false,
    error: null,
    createCoupon: vi.fn(),
    updateCoupon: vi.fn(),
    setCouponEnabled: vi.fn(),
    deleteCoupon: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useCoupons>)
}

describe('CouponsPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('shows the empty state when there are no coupons', () => {
    mockUseCoupons()
    render(<CouponsPage />)
    expect(screen.getByText('Nenhum cupom cadastrado ainda.')).toBeInTheDocument()
  })

  it('renders a row per coupon with discount, code and status', () => {
    mockUseCoupons({ coupons: [baseCoupon] })
    render(<CouponsPage />)

    expect(screen.getByText('Desconto verão')).toBeInTheDocument()
    expect(screen.getByText('-10%')).toBeInTheDocument()
    expect(screen.getByText(/código VERAO10/)).toBeInTheDocument()
    expect(screen.getByText('Ativo')).toBeInTheDocument()
  })

  it('calls setCouponEnabled when the toggle is clicked', async () => {
    const setCouponEnabled = vi.fn()
    mockUseCoupons({ coupons: [baseCoupon], setCouponEnabled })
    render(<CouponsPage />)

    await userEvent.click(screen.getByRole('switch'))

    expect(setCouponEnabled).toHaveBeenCalledWith({ couponId: 'c1', enabled: false })
  })

  it('opens a confirmation modal and calls deleteCoupon on confirm', async () => {
    const deleteCoupon = vi.fn().mockResolvedValue(undefined)
    mockUseCoupons({ coupons: [baseCoupon], deleteCoupon })
    render(<CouponsPage />)

    await userEvent.click(screen.getByLabelText('Remover'))
    const dialog = screen.getByRole('dialog', { name: 'Remover cupom?' })
    expect(within(dialog).getByText(/será removido permanentemente/)).toBeInTheDocument()

    await userEvent.click(within(dialog).getByRole('button', { name: 'Remover' }))

    await waitFor(() => expect(deleteCoupon).toHaveBeenCalledWith('c1'))
  })

  it('opens the create dialog when "Criar cupom" is clicked', async () => {
    mockUseCoupons()
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
      status: 'authenticated',
      errorCode: null,
      signInWithToken: vi.fn(),
      signOut: vi.fn(),
    })
    render(<CouponsPage />)

    await userEvent.click(screen.getByText('+ Criar cupom'))

    expect(screen.getByRole('dialog', { name: 'Criar cupom' })).toBeInTheDocument()
  })

  it('shows a loading spinner while coupons are loading', () => {
    mockUseCoupons({ isLoading: true })
    const { container } = render(<CouponsPage />)
    expect(container.querySelector('.animate-spin')).toBeInTheDocument()
  })
})
