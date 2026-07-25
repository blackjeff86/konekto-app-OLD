/** Portado de apps/konekto_portal/lib/data/stays_repository.dart. */
import { apiRequest } from './client'
import type { NewStayInput, Stay } from '@/types/stay'

export function listStays(hotelId: string, token: string): Promise<Stay[]> {
  return apiRequest<Stay[]>(`/api/hotels/${hotelId}/stays`, {
    token,
    errorMessage: 'Falha ao carregar quartos.',
  })
}

export function getStay(hotelId: string, stayId: string, token: string): Promise<Stay> {
  return apiRequest<Stay>(`/api/hotels/${hotelId}/stays/${stayId}`, {
    token,
    errorMessage: 'Falha ao carregar o quarto.',
  })
}

export function createStay(hotelId: string, token: string, input: NewStayInput): Promise<Stay> {
  return apiRequest<Stay>(`/api/hotels/${hotelId}/stays`, {
    method: 'POST',
    token,
    body: input,
    errorMessage: 'Falha ao criar o quarto.',
  })
}

/** Estende (ou antecipa) a saída — muda só a data de checkout. */
export function extendStay(
  hotelId: string,
  stayId: string,
  token: string,
  checkOutDate: string,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/stays/${stayId}`, {
    method: 'PATCH',
    token,
    body: { checkOutDate },
    errorMessage: 'Falha ao estender a estadia.',
  })
}

/** Move a estadia pra outro quarto físico. */
export function changeRoom(
  hotelId: string,
  stayId: string,
  token: string,
  roomId: string,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/stays/${stayId}`, {
    method: 'PATCH',
    token,
    body: { roomId },
    conflictMessage: 'Esse quarto já está ocupado por outra estadia.',
    errorMessage: 'Falha ao trocar o quarto.',
  })
}

/** Fecha a conta: marca a estadia como encerrada e revoga todos os códigos de acesso. */
export function closeStay(hotelId: string, stayId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/stays/${stayId}`, {
    method: 'PATCH',
    token,
    body: { close: true },
    errorMessage: 'Falha ao fechar a conta.',
  })
}

export function sendMessage(
  hotelId: string,
  stayId: string,
  token: string,
  message: string,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/stays/${stayId}/messages`, {
    method: 'POST',
    token,
    body: { message },
    errorMessage: 'Falha ao enviar a mensagem.',
  })
}

export function markMessagesRead(hotelId: string, stayId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/stays/${stayId}/messages/read`, {
    method: 'POST',
    token,
    errorMessage: 'Falha ao marcar mensagens como lidas.',
  })
}

export async function getUnreadMessagesCount(hotelId: string, token: string): Promise<number> {
  const body = await apiRequest<{ count?: number }>(
    `/api/hotels/${hotelId}/stays/messages/unread-count`,
    { token, errorMessage: 'Falha ao carregar contagem de mensagens.' },
  )
  return body.count ?? 0
}
