import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { useCoupons } from './useCoupons'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/coupons', () => ({
  listCoupons: vi.fn(),
  createCoupon: vi.fn(),
  updateCoupon: vi.fn(),
  setCouponEnabled: vi.fn(),
  deleteCoupon: vi.fn(),
}))

import { useAuth } from '@/lib/auth/AuthProvider'
import { createCoupon, deleteCoupon, listCoupons } from '@/lib/api/coupons'

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

describe('useCoupons', () => {
  afterEach(() => vi.clearAllMocks())

  it('loads coupons for the current session hotelId once authenticated', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(listCoupons).mockResolvedValue([
      {
        id: 'c1',
        title: 'Verão',
        description: '',
        code: 'V10',
        discountType: 'percentage',
        discountValue: 10,
        minOrderValue: null,
        imageUrl: null,
        validFrom: null,
        validUntil: null,
        usageLimit: null,
        perGuestLimit: 1,
        enabled: true,
      },
    ])

    const { result } = renderHook(() => useCoupons(), { wrapper })

    await waitFor(() => expect(result.current.coupons).toHaveLength(1))
    expect(listCoupons).toHaveBeenCalledWith('h1', 'tok')
  })

  it('does not fetch when there is no authenticated session yet', () => {
    vi.mocked(useAuth).mockReturnValue({ session: null, token: null } as ReturnType<typeof useAuth>)

    renderHook(() => useCoupons(), { wrapper })

    expect(listCoupons).not.toHaveBeenCalled()
  })

  it('createCoupon calls the API with the session hotelId/token and invalidates the list', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(listCoupons).mockResolvedValue([])
    vi.mocked(createCoupon).mockResolvedValue({
      id: 'new',
      title: 'Nova',
      description: '',
      code: 'NEW',
      discountType: 'percentage',
      discountValue: 5,
      minOrderValue: null,
      imageUrl: null,
      validFrom: null,
      validUntil: null,
      usageLimit: null,
      perGuestLimit: 1,
      enabled: true,
    })

    const { result } = renderHook(() => useCoupons(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.createCoupon({
      title: 'Nova',
      description: '',
      code: 'NEW',
      discountType: 'percentage',
      discountValue: 5,
      perGuestLimit: 1,
    })

    expect(createCoupon).toHaveBeenCalledWith('h1', 'tok', expect.objectContaining({ code: 'NEW' }))
    await waitFor(() => expect(listCoupons).toHaveBeenCalledTimes(2))
  })

  it('deleteCoupon calls the API with the coupon id and invalidates the list', async () => {
    vi.mocked(useAuth).mockReturnValue({
      session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
      token: 'tok',
    } as ReturnType<typeof useAuth>)
    vi.mocked(listCoupons).mockResolvedValue([])
    vi.mocked(deleteCoupon).mockResolvedValue(undefined)

    const { result } = renderHook(() => useCoupons(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await result.current.deleteCoupon('c1')

    expect(deleteCoupon).toHaveBeenCalledWith('h1', 'c1', 'tok')
  })
})
