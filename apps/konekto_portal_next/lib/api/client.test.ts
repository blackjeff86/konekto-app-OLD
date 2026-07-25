import { afterEach, describe, expect, it, vi } from 'vitest'
import { apiRequest, ApiError } from './client'

function mockFetchOnce(response: Partial<Response> & { text: () => Promise<string> }) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      ...response,
    } as Response),
  )
}

describe('apiRequest', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('returns parsed JSON on a 200 response', async () => {
    mockFetchOnce({
      ok: true,
      status: 200,
      text: async () => JSON.stringify({ id: '1', name: 'Cupom' }),
    })

    const result = await apiRequest<{ id: string; name: string }>('/api/hotels/h1/coupons', {
      token: 'tok',
    })

    expect(result).toEqual({ id: '1', name: 'Cupom' })
  })

  it('maps a 409 response to the caller-provided conflict message', async () => {
    mockFetchOnce({
      ok: false,
      status: 409,
      text: async () => '',
    })

    await expect(
      apiRequest('/api/hotels/h1/coupons', {
        token: 'tok',
        conflictMessage: 'Já existe um cupom com esse código.',
      }),
    ).rejects.toMatchObject({
      message: 'Já existe um cupom com esse código.',
      status: 409,
    } satisfies Partial<ApiError>)
  })

  it('maps a non-2xx response without a matching conflictMessage to the generic errorMessage', async () => {
    mockFetchOnce({
      ok: false,
      status: 500,
      text: async () => '',
    })

    await expect(
      apiRequest('/api/hotels/h1/coupons', {
        token: 'tok',
        errorMessage: 'Falha ao carregar cupons (status 500).',
      }),
    ).rejects.toMatchObject({ message: 'Falha ao carregar cupons (status 500).', status: 500 })
  })

  it('throws a typed ApiError when the network request itself fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')))

    await expect(apiRequest('/api/hotels/h1/coupons', { token: 'tok' })).rejects.toBeInstanceOf(
      ApiError,
    )
  })

  it('returns undefined for an empty response body (e.g. DELETE/PATCH with no return payload)', async () => {
    mockFetchOnce({ ok: true, status: 200, text: async () => '' })

    const result = await apiRequest('/api/hotels/h1/coupons/c1', {
      method: 'DELETE',
      token: 'tok',
    })

    expect(result).toBeUndefined()
  })

  it('omits the Authorization header entirely when no token is given (public endpoints)', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => '[]',
    } as Response)
    vi.stubGlobal('fetch', fetchMock)

    await apiRequest('/api/hotels/h1/services')

    const [, init] = fetchMock.mock.calls[0]
    expect(init.headers.Authorization).toBeUndefined()
  })
})
