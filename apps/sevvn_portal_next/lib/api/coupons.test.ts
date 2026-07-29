import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  createCoupon,
  deleteCoupon,
  listCoupons,
  setCouponEnabled,
  updateCoupon,
} from './coupons'
import type { CouponInput } from '@/types/coupon'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  const fetchMock = vi.fn().mockResolvedValue({
    ok: response.ok,
    status: response.status,
    text: async () => (response.body !== undefined ? JSON.stringify(response.body) : ''),
  } as Response)
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

const input: CouponInput = {
  title: 'Desconto verão',
  description: 'Promo de verão',
  code: 'VERAO10',
  discountType: 'percentage',
  discountValue: 10,
  perGuestLimit: 1,
}

describe('coupons API', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('listCoupons hits GET /api/hotels/:hotelId/coupons with the bearer token', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200, body: [] })
    await listCoupons('h1', 'tok')
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:3000/api/hotels/h1/coupons',
      expect.objectContaining({ method: 'GET', headers: { Authorization: 'Bearer tok' } }),
    )
  })

  it('createCoupon posts the input and maps 409 to the duplicate-code message', async () => {
    mockFetch({ ok: false, status: 409 })
    await expect(createCoupon('h1', 'tok', input)).rejects.toMatchObject({
      message: 'Já existe um cupom com esse código.',
      status: 409,
    })
  })

  it('updateCoupon PATCHes the coupon id', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await updateCoupon('h1', 'c1', 'tok', input)
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:3000/api/hotels/h1/coupons/c1',
      expect.objectContaining({ method: 'PATCH' }),
    )
  })

  it('setCouponEnabled sends only the enabled flag', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await setCouponEnabled('h1', 'c1', 'tok', false)
    const call = fetchMock.mock.calls[0]
    expect(JSON.parse(call[1].body)).toEqual({ enabled: false })
  })

  it('deleteCoupon maps 409 to the in-use message', async () => {
    mockFetch({ ok: false, status: 409 })
    await expect(deleteCoupon('h1', 'c1', 'tok')).rejects.toMatchObject({
      message: 'Esse cupom já foi usado em pedidos — desative-o em vez de remover.',
    })
  })
})
