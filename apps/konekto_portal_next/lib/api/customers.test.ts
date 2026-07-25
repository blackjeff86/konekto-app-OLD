import { afterEach, describe, expect, it, vi } from 'vitest'
import { sendPromo } from './customers'

function mockFetch(response: { status: number; body?: unknown }) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      status: response.status,
      json: async () => response.body,
    } as Response),
  )
}

describe('sendPromo', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('resolves on a 200 response', async () => {
    mockFetch({ status: 200 })
    await expect(sendPromo('h1', '12345678900', 'tok', 'c1')).resolves.toBeUndefined()
  })

  it('maps the customer_no_email error code to a PT-BR message', async () => {
    mockFetch({ status: 400, body: { error: 'customer_no_email' } })
    await expect(sendPromo('h1', '12345678900', 'tok', 'c1')).rejects.toMatchObject({
      message: 'Esse cliente não tem e-mail cadastrado.',
    })
  })

  it('falls back to a generic message for an unrecognized error code', async () => {
    mockFetch({ status: 500, body: { error: 'something_else' } })
    await expect(sendPromo('h1', '12345678900', 'tok', 'c1')).rejects.toMatchObject({
      message: 'Falha ao enviar e-mail (status 500).',
    })
  })
})
