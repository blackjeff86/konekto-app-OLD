import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  createItem,
  createService,
  createTableType,
  deleteItem,
  deleteService,
  deleteTableType,
  listMinibarItems,
  listServices,
  updateItem,
  updateService,
  updateTableType,
} from './services'
import type { ServiceItemInput } from '@/types/service'

const SAMPLE_ITEM_INPUT: ServiceItemInput = {
  name: 'Água',
  description: '',
  price: 5,
  imageUrl: null,
  location: null,
  category: null,
  extraInfo: null,
  durationMinutes: null,
  capacityPerSlot: null,
  availableDaysOfWeek: [],
  availabilityStartMinute: null,
  availabilityEndMinute: null,
  isMinibarItem: true,
  partnerId: null,
  paymentMode: 'hotel',
}

describe('listMinibarItems', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('fetches each room_service detail and returns only isMinibarItem items', async () => {
    const fetchMock = vi.fn().mockImplementation(async (url: string) => {
      if (url.endsWith('/services')) {
        return {
          ok: true,
          status: 200,
          text: async () =>
            JSON.stringify([
              { id: 'svc1', type: 'room_service' },
              { id: 'svc2', type: 'restaurant' },
            ]),
        }
      }
      if (url.endsWith('/services/svc1')) {
        return {
          ok: true,
          status: 200,
          text: async () =>
            JSON.stringify({
              id: 'svc1',
              name: 'Serviço de Quarto',
              type: 'room_service',
              items: [
                { id: 'i1', name: 'Água', price: 5, isMinibarItem: true },
                { id: 'i2', name: 'Toalha extra', price: null, isMinibarItem: false },
              ],
            }),
        }
      }
      throw new Error(`unexpected fetch: ${url}`)
    })
    vi.stubGlobal('fetch', fetchMock)

    const result = await listMinibarItems('h1')

    expect(result).toEqual([
      { service: { id: 'svc1', name: 'Serviço de Quarto' }, item: { id: 'i1', name: 'Água', price: 5, isMinibarItem: true } },
    ])
    // Não busca o detalhe de serviços que não são room_service.
    expect(fetchMock).not.toHaveBeenCalledWith(expect.stringContaining('svc2'), expect.anything())
  })

  it('sends no Authorization header (endpoint público)', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => '[]',
    } as Response)
    vi.stubGlobal('fetch', fetchMock)

    await listMinibarItems('h1')

    const [, init] = fetchMock.mock.calls[0]
    expect(init.headers.Authorization).toBeUndefined()
  })
})

describe('listServices', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('fetches the detail of every service (any type) to fill in items', async () => {
    const fetchMock = vi.fn().mockImplementation(async (url: string) => {
      if (url.endsWith('/services')) {
        return {
          ok: true,
          status: 200,
          text: async () => JSON.stringify([{ id: 'svc1', type: 'restaurant' }]),
        }
      }
      if (url.endsWith('/services/svc1')) {
        return {
          ok: true,
          status: 200,
          text: async () => JSON.stringify({ id: 'svc1', name: 'Restaurante', type: 'restaurant', items: [] }),
        }
      }
      throw new Error(`unexpected fetch: ${url}`)
    })
    vi.stubGlobal('fetch', fetchMock)

    const result = await listServices('h1')

    expect(result).toEqual([{ id: 'svc1', name: 'Restaurante', type: 'restaurant', items: [] }])
  })
})

describe('service CRUD', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('createService posts operating hours only when provided', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 201, text: async () => '{}' })
    vi.stubGlobal('fetch', fetchMock)

    await createService('h1', 'tok', {
      name: 'Spa',
      slug: 'spa',
      icon: 'spa',
      description: '',
      type: 'activity',
      category: 'Bem-estar',
    })

    const [, init] = fetchMock.mock.calls[0]
    const body = JSON.parse(init.body)
    expect(body.operatingDaysOfWeek).toBeUndefined()
  })

  it('updateService sends enabled toggle', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '' })
    vi.stubGlobal('fetch', fetchMock)

    await updateService('h1', 'svc1', 'tok', { enabled: false })

    const [, init] = fetchMock.mock.calls[0]
    expect(init.method).toBe('PATCH')
    expect(JSON.parse(init.body)).toEqual({ enabled: false })
  })

  it('deleteService calls DELETE with Authorization', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '' })
    vi.stubGlobal('fetch', fetchMock)

    await deleteService('h1', 'svc1', 'tok')

    const [, init] = fetchMock.mock.calls[0]
    expect(init.method).toBe('DELETE')
    expect(init.headers.Authorization).toBe('Bearer tok')
  })
})

describe('item CRUD', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('createItem posts the item payload', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 201,
      text: async () => JSON.stringify({ id: 'i1', ...SAMPLE_ITEM_INPUT, position: 0, translations: {}, translationsAutoGenerated: true }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const result = await createItem('h1', 'svc1', 'tok', SAMPLE_ITEM_INPUT)

    expect(result.id).toBe('i1')
    const [, init] = fetchMock.mock.calls[0]
    expect(JSON.parse(init.body)).toEqual(SAMPLE_ITEM_INPUT)
  })

  it('updateItem sends PATCH', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => JSON.stringify({ id: 'i1', ...SAMPLE_ITEM_INPUT, position: 0, translations: {}, translationsAutoGenerated: true }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await updateItem('h1', 'svc1', 'i1', 'tok', SAMPLE_ITEM_INPUT)

    const [, init] = fetchMock.mock.calls[0]
    expect(init.method).toBe('PATCH')
  })

  it('deleteItem sends DELETE', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '' })
    vi.stubGlobal('fetch', fetchMock)

    await deleteItem('h1', 'svc1', 'i1', 'tok')

    const [, init] = fetchMock.mock.calls[0]
    expect(init.method).toBe('DELETE')
  })
})

describe('table type CRUD', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('createTableType posts label/seats/quantity', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 201,
      text: async () => JSON.stringify({ id: 't1', label: 'Varanda', seats: 4, quantity: 3 }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const result = await createTableType('h1', 'svc1', 'tok', { label: 'Varanda', seats: 4, quantity: 3 })

    expect(result).toEqual({ id: 't1', label: 'Varanda', seats: 4, quantity: 3 })
  })

  it('updateTableType sends PATCH', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => JSON.stringify({ id: 't1', label: null, seats: 2, quantity: 5 }),
    })
    vi.stubGlobal('fetch', fetchMock)

    await updateTableType('h1', 'svc1', 't1', 'tok', { label: null, seats: 2, quantity: 5 })

    const [, init] = fetchMock.mock.calls[0]
    expect(init.method).toBe('PATCH')
  })

  it('deleteTableType sends DELETE', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '' })
    vi.stubGlobal('fetch', fetchMock)

    await deleteTableType('h1', 'svc1', 't1', 'tok')

    const [, init] = fetchMock.mock.calls[0]
    expect(init.method).toBe('DELETE')
  })
})
