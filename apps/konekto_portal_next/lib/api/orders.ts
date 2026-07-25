/** Portado de apps/konekto_portal/lib/data/orders_repository.dart. */
import { apiRequest } from './client'
import type { Order, OrderStatus } from '@/types/order'

export function listOrders(hotelId: string, token: string): Promise<Order[]> {
  return apiRequest<Order[]>(`/api/hotels/${hotelId}/orders`, {
    token,
    errorMessage: 'Falha ao carregar pedidos.',
  })
}

export function updateOrderStatus(
  hotelId: string,
  orderId: string,
  token: string,
  status: OrderStatus,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/orders/${orderId}`, {
    method: 'PATCH',
    token,
    body: { status },
    errorMessage: 'Falha ao atualizar status.',
  })
}

/**
 * Recepção lança um consumo de frigobar em nome de um hóspede da estadia
 * (ex: item notado faltando na conferência do quarto) — só funciona pra
 * itens marcados como frigobar no catálogo.
 */
export function recordConsumption(
  hotelId: string,
  stayId: string,
  token: string,
  guestId: string,
  serviceItemId: string,
  quantity: number,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/stays/${stayId}/consumption`, {
    method: 'POST',
    token,
    body: { guestId, serviceItemId, quantity },
    errorMessage: 'Falha ao lançar consumo.',
  })
}
