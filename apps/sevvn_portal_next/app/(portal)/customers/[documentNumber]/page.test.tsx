import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Suspense } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import CustomerDetailPage from './page'

vi.mock('@/hooks/useCustomers', () => ({ useCustomers: vi.fn() }))
vi.mock('@/hooks/useCoupons', () => ({ useCoupons: vi.fn() }))

import { useCoupons } from '@/hooks/useCoupons'
import { useCustomers } from '@/hooks/useCustomers'

const customer = {
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
  visitsCount: 2,
  totalSpent: 300,
  firstVisit: '2026-01-01T00:00:00.000Z',
  lastVisit: '2026-07-01T00:00:00.000Z',
  stays: [
    {
      stayId: 's1',
      roomNumber: '101',
      checkInDate: '2026-01-01T00:00:00.000Z',
      checkOutDate: '2026-01-05T00:00:00.000Z',
      status: 'closed',
      nights: 4,
      spent: 300,
    },
  ],
}

const enabledCoupon = {
  id: 'c1',
  title: 'Verão',
  description: '',
  code: 'V10',
  discountType: 'percentage' as const,
  discountValue: 10,
  minOrderValue: null,
  imageUrl: null,
  validFrom: null,
  validUntil: null,
  usageLimit: null,
  perGuestLimit: 1,
  enabled: true,
}

function mockHooks({
  sendPromo = vi.fn(),
  coupons = [enabledCoupon],
}: { sendPromo?: ReturnType<typeof vi.fn>; coupons?: (typeof enabledCoupon)[] } = {}) {
  vi.mocked(useCustomers).mockReturnValue({
    customers: [customer],
    isLoading: false,
    error: null,
    sendPromo,
  } as unknown as ReturnType<typeof useCustomers>)
  vi.mocked(useCoupons).mockReturnValue({
    coupons,
    isLoading: false,
    error: null,
    createCoupon: vi.fn(),
    updateCoupon: vi.fn(),
    setCouponEnabled: vi.fn(),
    deleteCoupon: vi.fn(),
  } as unknown as ReturnType<typeof useCoupons>)
  return { sendPromo }
}

async function renderPage() {
  const paramsPromise = Promise.resolve({ documentNumber: '111' })
  await act(async () => {
    render(
      <Suspense fallback={<div>carregando</div>}>
        <CustomerDetailPage params={paramsPromise} />
      </Suspense>,
    )
  })
}

describe('CustomerDetailPage', () => {
  afterEach(() => vi.clearAllMocks())

  it('renders contact info, stats and stay history', async () => {
    mockHooks()
    await renderPage()

    expect(screen.getByText('Ana Silva')).toBeInTheDocument()
    expect(screen.getByText(/CPF · 111/)).toBeInTheDocument()
    expect(screen.getByText('Quarto 101')).toBeInTheDocument()
    expect(screen.getAllByText('R$ 300.00').length).toBeGreaterThan(0)
  })

  it('sends a promo email with the selected coupon', async () => {
    const { sendPromo } = mockHooks()
    sendPromo.mockResolvedValue(undefined)
    await renderPage()

    await userEvent.click(screen.getByRole('button', { name: 'Enviar e-mail' }))

    await waitFor(() =>
      expect(sendPromo).toHaveBeenCalledWith({
        documentNumber: '111',
        couponId: 'c1',
        message: '',
      }),
    )
    expect(await screen.findByText('E-mail enviado pra ana@example.com.')).toBeInTheDocument()
  })

  it('shows a message instead of the form when there are no enabled coupons', async () => {
    mockHooks({ coupons: [] })
    await renderPage()

    expect(
      screen.getByText(/Nenhum cupom ativo no momento/),
    ).toBeInTheDocument()
  })
})
