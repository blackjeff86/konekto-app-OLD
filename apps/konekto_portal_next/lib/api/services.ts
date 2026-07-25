/**
 * Portado de apps/konekto_portal/lib/data/service_repository.dart.
 *
 * NOTA: `GET /api/hotels/:hotelId/services` (lista) não inclui `items` na
 * resposta — lacuna conhecida no backend (mesma que já foi contornada no
 * app do hóspede). Contornamos aqui buscando o detalhe de cada serviço
 * (que SIM inclui `items`) em paralelo, em vez de tentar "consertar" o
 * endpoint compartilhado como parte desta migração — isso também garante
 * que a contagem de itens mostrada na lista do portal seja sempre correta.
 */
import { apiRequest } from './client'
import type { RestaurantTableType, Service, ServiceItem, ServiceItemInput, ServiceType } from '@/types/service'

interface ServiceStub {
  id: string
  type: ServiceType
}

export async function listServices(hotelId: string): Promise<Service[]> {
  const stubs = await apiRequest<ServiceStub[]>(`/api/hotels/${hotelId}/services`, {
    errorMessage: 'Falha ao carregar serviços.',
  })
  return Promise.all(stubs.map((stub) => getService(hotelId, stub.id)))
}

export function getService(hotelId: string, serviceId: string): Promise<Service> {
  return apiRequest<Service>(`/api/hotels/${hotelId}/services/${serviceId}`, {
    errorMessage: 'Falha ao carregar serviço.',
  })
}

/**
 * Diferente de `listServices`, busca o detalhe só dos serviços
 * `room_service` (filtra os stubs ANTES de buscar detalhe) — usado no
 * lançamento de consumo pela recepção, um caminho quente que não precisa
 * pagar o custo de buscar restaurantes/atividades irrelevantes.
 */
export async function listMinibarItems(hotelId: string): Promise<
  { service: Pick<Service, 'id' | 'name'>; item: ServiceItem }[]
> {
  const stubs = await apiRequest<ServiceStub[]>(`/api/hotels/${hotelId}/services`, {
    errorMessage: 'Falha ao carregar serviços.',
  })
  const roomServiceStubs = stubs.filter((stub) => stub.type === 'room_service')

  const fullServices = await Promise.all(roomServiceStubs.map((stub) => getService(hotelId, stub.id)))

  return fullServices.flatMap((service) =>
    service.items
      .filter((item) => item.isMinibarItem)
      .map((item) => ({ service: { id: service.id, name: service.name }, item })),
  )
}

export interface OperatingHoursInput {
  operatingDaysOfWeek: number[] | null
  operatingStartMinute: number | null
  operatingEndMinute: number | null
}

export interface CreateServiceInput {
  name: string
  slug: string
  icon: string
  description: string
  type: ServiceType
  category: string
  operatingHours?: OperatingHoursInput
}

export function createService(hotelId: string, token: string, input: CreateServiceInput): Promise<Service> {
  return apiRequest<Service>(`/api/hotels/${hotelId}/services`, {
    method: 'POST',
    token,
    body: {
      name: input.name,
      slug: input.slug,
      icon: input.icon,
      description: input.description,
      type: input.type,
      category: input.category,
      ...(input.operatingHours ?? {}),
    },
    errorMessage: 'Falha ao criar serviço.',
  })
}

export interface UpdateServiceInput {
  name?: string
  icon?: string
  description?: string
  category?: string
  enabled?: boolean
  /**
   * Quando informado, manda os 3 campos de horário sempre juntos (mesmo
   * `null`/vazio) — diferente dos demais campos (omitidos quando
   * ausentes = "não mexer"), horário de funcionamento não tem um campo
   * "interruptor" único, então desligar precisa zerar os 3 no mesmo PATCH.
   */
  operatingHours?: OperatingHoursInput
}

export function updateService(
  hotelId: string,
  serviceId: string,
  token: string,
  input: UpdateServiceInput,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/services/${serviceId}`, {
    method: 'PATCH',
    token,
    body: {
      ...(input.name !== undefined ? { name: input.name } : {}),
      ...(input.icon !== undefined ? { icon: input.icon } : {}),
      ...(input.description !== undefined ? { description: input.description } : {}),
      ...(input.category !== undefined ? { category: input.category } : {}),
      ...(input.enabled !== undefined ? { enabled: input.enabled } : {}),
      ...(input.operatingHours ?? {}),
    },
    errorMessage: 'Falha ao atualizar serviço.',
  })
}

export function deleteService(hotelId: string, serviceId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/services/${serviceId}`, {
    method: 'DELETE',
    token,
    errorMessage: 'Falha ao remover serviço.',
  })
}

export function createItem(
  hotelId: string,
  serviceId: string,
  token: string,
  item: ServiceItemInput,
): Promise<ServiceItem> {
  return apiRequest<ServiceItem>(`/api/hotels/${hotelId}/services/${serviceId}/items`, {
    method: 'POST',
    token,
    body: item,
    errorMessage: 'Falha ao criar item.',
  })
}

export function updateItem(
  hotelId: string,
  serviceId: string,
  itemId: string,
  token: string,
  item: ServiceItemInput,
): Promise<ServiceItem> {
  return apiRequest<ServiceItem>(`/api/hotels/${hotelId}/services/${serviceId}/items/${itemId}`, {
    method: 'PATCH',
    token,
    body: item,
    errorMessage: 'Falha ao atualizar item.',
  })
}

export function deleteItem(hotelId: string, serviceId: string, itemId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/services/${serviceId}/items/${itemId}`, {
    method: 'DELETE',
    token,
    errorMessage: 'Falha ao remover item.',
  })
}

export function listTableTypes(hotelId: string, serviceId: string): Promise<RestaurantTableType[]> {
  return apiRequest<RestaurantTableType[]>(`/api/hotels/${hotelId}/services/${serviceId}/table-types`, {
    errorMessage: 'Falha ao carregar tipos de mesa.',
  })
}

export interface TableTypeInput {
  label: string | null
  seats: number
  quantity: number
}

export function createTableType(
  hotelId: string,
  serviceId: string,
  token: string,
  input: TableTypeInput,
): Promise<RestaurantTableType> {
  return apiRequest<RestaurantTableType>(`/api/hotels/${hotelId}/services/${serviceId}/table-types`, {
    method: 'POST',
    token,
    body: input,
    errorMessage: 'Falha ao criar tipo de mesa.',
  })
}

export function updateTableType(
  hotelId: string,
  serviceId: string,
  tableTypeId: string,
  token: string,
  input: TableTypeInput,
): Promise<RestaurantTableType> {
  return apiRequest<RestaurantTableType>(
    `/api/hotels/${hotelId}/services/${serviceId}/table-types/${tableTypeId}`,
    {
      method: 'PATCH',
      token,
      body: input,
      errorMessage: 'Falha ao atualizar tipo de mesa.',
    },
  )
}

export function deleteTableType(
  hotelId: string,
  serviceId: string,
  tableTypeId: string,
  token: string,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/services/${serviceId}/table-types/${tableTypeId}`, {
    method: 'DELETE',
    token,
    errorMessage: 'Falha ao remover tipo de mesa.',
  })
}
