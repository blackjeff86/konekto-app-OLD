import { afterEach, describe, expect, it, vi } from 'vitest'
import { listGuests, lookupGuestByDocument } from './guests'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      ok: response.ok,
      status: response.status,
      text: async () => (response.body !== undefined ? JSON.stringify(response.body) : ''),
    } as Response),
  )
}

describe('guests API', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('listGuests hits GET /api/hotels/:hotelId/guests', async () => {
    mockFetch({ ok: true, status: 200, body: [] })
    await expect(listGuests('h1', 'tok')).resolves.toEqual([])
  })

  it('lookupGuestByDocument returns null on a 404 (new guest, not an error)', async () => {
    mockFetch({ ok: false, status: 404 })
    await expect(lookupGuestByDocument('h1', 'tok', '12345678900')).resolves.toBeNull()
  })

  it('lookupGuestByDocument returns the result on 200', async () => {
    mockFetch({
      ok: true,
      status: 200,
      body: {
        firstName: 'Ana',
        lastName: 'Silva',
        documentType: 'cpf',
        documentNumber: '12345678900',
        phoneCountryCode: '+55',
        phoneNumber: '11999999999',
        country: 'Brasil',
      },
    })
    const result = await lookupGuestByDocument('h1', 'tok', '12345678900')
    expect(result?.firstName).toBe('Ana')
  })

  it('lookupGuestByDocument rethrows non-404 failures', async () => {
    mockFetch({ ok: false, status: 500 })
    await expect(lookupGuestByDocument('h1', 'tok', '12345678900')).rejects.toMatchObject({
      status: 500,
    })
  })
})
