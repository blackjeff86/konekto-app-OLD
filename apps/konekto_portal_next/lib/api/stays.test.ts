import { afterEach, describe, expect, it, vi } from 'vitest'
import { changeRoom, closeStay, extendStay, getUnreadMessagesCount } from './stays'

function mockFetch(response: { ok: boolean; status: number; body?: unknown }) {
  const fetchMock = vi.fn().mockResolvedValue({
    ok: response.ok,
    status: response.status,
    text: async () => (response.body !== undefined ? JSON.stringify(response.body) : ''),
  } as Response)
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

describe('stays API', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('extendStay PATCHes only checkOutDate', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await extendStay('h1', 's1', 'tok', '2026-08-01T00:00:00.000Z')
    const call = fetchMock.mock.calls[0]
    expect(JSON.parse(call[1].body)).toEqual({ checkOutDate: '2026-08-01T00:00:00.000Z' })
  })

  it('changeRoom maps 409 to the room-occupied message', async () => {
    mockFetch({ ok: false, status: 409 })
    await expect(changeRoom('h1', 's1', 'tok', 'r2')).rejects.toMatchObject({
      message: 'Esse quarto já está ocupado por outra estadia.',
    })
  })

  it('closeStay sends { close: true }', async () => {
    const fetchMock = mockFetch({ ok: true, status: 200 })
    await closeStay('h1', 's1', 'tok')
    const call = fetchMock.mock.calls[0]
    expect(JSON.parse(call[1].body)).toEqual({ close: true })
  })

  it('getUnreadMessagesCount defaults to 0 when count is missing', async () => {
    mockFetch({ ok: true, status: 200, body: {} })
    await expect(getUnreadMessagesCount('h1', 'tok')).resolves.toBe(0)
  })
})
