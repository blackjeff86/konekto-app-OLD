import { afterEach, describe, expect, it, vi } from 'vitest'
import { createPartner, deletePartner, listPartners, updatePartner } from './partners'
import type { PartnerInput } from '@/types/partner'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  const fetchMock = vi.fn().mockResolvedValue({
    ok: response.ok,
    status: response.status,
    text: async () => (response.body !== undefined ? JSON.stringify(response.body) : ''),
  } as Response)
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

const input: PartnerInput = { name: 'Spa Terceirizado' }

describe('partners API', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('listPartners hits GET /api/hotels/:hotelId/partners', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200, body: [] })
    await listPartners('h1', 'tok')
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:3000/api/hotels/h1/partners',
      expect.objectContaining({ method: 'GET' }),
    )
  })

  it('createPartner posts the input', async () => {
    const fetchMock = mockFetch({ ok: true, status: 201, body: { id: 'p1', ...input } })
    await createPartner('h1', 'tok', input)
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:3000/api/hotels/h1/partners',
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('updatePartner PATCHes the partner id', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await updatePartner('h1', 'p1', 'tok', input)
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:3000/api/hotels/h1/partners/p1',
      expect.objectContaining({ method: 'PATCH' }),
    )
  })

  it('deletePartner maps 409 to the in-use message', async () => {
    mockFetch({ ok: false, status: 409 })
    await expect(deletePartner('h1', 'p1', 'tok')).rejects.toMatchObject({
      message: 'Esse parceiro está vinculado a itens do catálogo — desvincule antes de remover.',
      status: 409,
    })
  })
})
