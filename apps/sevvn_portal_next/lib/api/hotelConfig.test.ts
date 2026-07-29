import { afterEach, describe, expect, it, vi } from 'vitest'
import { getWifiSettings, updateBranding, updatePromoImages } from './hotelConfig'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  const fetchMock = vi.fn().mockResolvedValue({
    ok: response.ok,
    status: response.status,
    text: async () => (response.body !== undefined ? JSON.stringify(response.body) : ''),
  } as Response)
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

describe('hotelConfig API', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('getWifiSettings returns empty strings on a 404 (not yet configured)', async () => {
    mockFetch({ ok: false, status: 404 })
    await expect(getWifiSettings('h1', 'tok')).resolves.toEqual({ networkName: '', password: '' })
  })

  it('getWifiSettings maps the wifi.network_name/password fields', async () => {
    mockFetch({ ok: true, status: 200, body: { wifi: { network_name: 'Hotel WiFi', password: 'abc123' } } })
    await expect(getWifiSettings('h1', 'tok')).resolves.toEqual({ networkName: 'Hotel WiFi', password: 'abc123' })
  })

  it('getWifiSettings sends Authorization — the guestInfo doc is private staff-only on the backend', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200, body: {} })
    await getWifiSettings('h1', 'tok')
    const [, init] = fetchMock.mock.calls[0]
    expect(init.headers.Authorization).toBe('Bearer tok')
  })

  it('updateBranding omits keys whose value was not provided', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await updateBranding('h1', 'tok', { name: 'Novo nome' })
    const call = fetchMock.mock.calls[0]
    expect(JSON.parse(call[1].body)).toEqual({ hotelInfo: { name: 'Novo nome' } })
  })

  it('updatePromoImages sends the full images array plus carouselEnabled', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await updatePromoImages('h1', 'tok', ['https://a.png', 'https://b.png'], 300)
    const call = fetchMock.mock.calls[0]
    expect(JSON.parse(call[1].body)).toEqual({
      hotelInfo: {
        promoImages: { images: ['https://a.png', 'https://b.png'], carouselHeight: 300, carouselEnabled: true },
      },
    })
  })
})
