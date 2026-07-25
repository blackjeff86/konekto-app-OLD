/** Portado de apps/konekto_portal/lib/data/support_repository.dart. */
import { apiRequest } from './client'
import type { SupportMessage } from '@/types/support'

export function listSupportMessages(hotelId: string, token: string): Promise<SupportMessage[]> {
  return apiRequest<SupportMessage[]>(`/api/hotels/${hotelId}/support-messages`, {
    token,
    errorMessage: 'Falha ao carregar as mensagens de suporte.',
  })
}

export function sendSupportMessage(hotelId: string, token: string, message: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/support-messages`, {
    method: 'POST',
    token,
    body: { message },
    errorMessage: 'Falha ao enviar a mensagem.',
  })
}

export function markSupportMessagesRead(hotelId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/support-messages/read`, {
    method: 'POST',
    token,
    errorMessage: 'Falha ao marcar mensagens como lidas.',
  })
}
