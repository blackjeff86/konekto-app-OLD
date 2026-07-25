import { afterEach, describe, expect, it, vi } from 'vitest'
import { listOrders, recordConsumption, updateOrderStatus } from './orders'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  const fetchMock = vi.fn().mockResolvedValue({
    ok: response.ok,
    status: response.status,
    text: async () => (response.body !== undefined ? JSON.stringify(response.body) : ''),
  } as Response)
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

describe('orders API', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('listOrders hits GET /api/hotels/:hotelId/orders', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200, body: [] })
    await listOrders('h1', 'tok')
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:3000/api/hotels/h1/orders',
      expect.objectContaining({ method: 'GET' }),
    )
  })

  it('updateOrderStatus PATCHes the order id with the new status', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await updateOrderStatus('h1', 'o1', 'tok', 'in_progress')
    const call = fetchMock.mock.calls[0]
    expect(call[0]).toBe('http://localhost:3000/api/hotels/h1/orders/o1')
    expect(JSON.parse(call[1].body)).toEqual({ status: 'in_progress' })
  })

  it('recordConsumption posts to the stay consumption endpoint', async () => {
    const fetchMock = mockFetch({ ok: true, status: 201 })
    await recordConsumption('h1', 's1', 'tok', 'g1', 'i1', 2)
    const call = fetchMock.mock.calls[0]
    expect(call[0]).toBe('http://localhost:3000/api/hotels/h1/stays/s1/consumption')
    expect(JSON.parse(call[1].body)).toEqual({ guestId: 'g1', serviceItemId: 'i1', quantity: 2 })
  })
})
