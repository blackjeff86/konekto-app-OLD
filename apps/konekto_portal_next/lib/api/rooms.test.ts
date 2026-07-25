import { afterEach, describe, expect, it, vi } from 'vitest'
import { listRooms } from './rooms'

function mockFetch(body: unknown) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => JSON.stringify(body),
    } as Response),
  )
}

describe('listRooms', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('maps a free room (activeStay null)', async () => {
    mockFetch([{ id: 'r1', number: '101', description: null, activeStay: null }])
    const rooms = await listRooms('h1', 'tok')
    expect(rooms).toEqual([{ id: 'r1', number: '101', description: null, activeStay: null }])
  })

  it('computes consumptionTotal from nested guest orders, same as RoomActiveStay.fromJson', async () => {
    mockFetch([
      {
        id: 'r1',
        number: '101',
        description: null,
        activeStay: {
          id: 's1',
          checkInDate: '2026-07-01T00:00:00.000Z',
          checkOutDate: '2026-07-10T00:00:00.000Z',
          guests: [
            { orders: [{ price: 10, quantity: 2 }, { price: null, quantity: 1 }] },
            { orders: [{ price: 5, quantity: 1 }] },
          ],
        },
      },
    ])

    const rooms = await listRooms('h1', 'tok')

    expect(rooms[0].activeStay).toMatchObject({ guestCount: 2, consumptionTotal: 25 })
  })

  it('treats a missing quantity as 1 and null price as excluded from the total', async () => {
    mockFetch([
      {
        id: 'r1',
        number: '101',
        description: null,
        activeStay: {
          id: 's1',
          checkInDate: '2026-07-01T00:00:00.000Z',
          checkOutDate: '2026-07-10T00:00:00.000Z',
          guests: [{ orders: [{ price: 8 }] }],
        },
      },
    ])

    const rooms = await listRooms('h1', 'tok')

    expect(rooms[0].activeStay?.consumptionTotal).toBe(8)
  })
})
