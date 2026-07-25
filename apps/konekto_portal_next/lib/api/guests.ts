/** Portado de apps/konekto_portal/lib/data/guests_repository.dart. */
import { apiRequest, ApiError } from './client'
import type { Guest, GuestEditInput, GuestLookupResult, NewGuestInput } from '@/types/guest'

export function listGuests(hotelId: string, token: string): Promise<Guest[]> {
  return apiRequest<Guest[]>(`/api/hotels/${hotelId}/guests`, {
    token,
    errorMessage: 'Falha ao carregar hóspedes.',
  })
}

/** Busca o cadastro mais recente pelo documento — null quando é um hóspede novo (404 da API). */
export async function lookupGuestByDocument(
  hotelId: string,
  token: string,
  documentNumber: string,
): Promise<GuestLookupResult | null> {
  try {
    return await apiRequest<GuestLookupResult>(
      `/api/hotels/${hotelId}/guests/lookup?documentNumber=${encodeURIComponent(documentNumber)}`,
      { token, errorMessage: 'Falha ao buscar hóspede.' },
    )
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null
    throw error
  }
}

export function getGuest(hotelId: string, guestId: string, token: string): Promise<Guest> {
  return apiRequest<Guest>(`/api/hotels/${hotelId}/guests/${guestId}`, {
    token,
    errorMessage: 'Falha ao carregar o hóspede.',
  })
}

export function createGuest(hotelId: string, token: string, input: NewGuestInput): Promise<Guest> {
  return apiRequest<Guest>(`/api/hotels/${hotelId}/guests`, {
    method: 'POST',
    token,
    body: input,
    errorMessage: 'Falha ao criar hóspede.',
  })
}

export function updateGuest(
  hotelId: string,
  guestId: string,
  token: string,
  input: GuestEditInput,
): Promise<Guest> {
  return apiRequest<Guest>(`/api/hotels/${hotelId}/guests/${guestId}`, {
    method: 'PATCH',
    token,
    body: input,
    errorMessage: 'Falha ao atualizar o cadastro.',
  })
}

export function revokeGuest(hotelId: string, guestId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/guests/${guestId}`, {
    method: 'DELETE',
    token,
    errorMessage: 'Falha ao revogar hóspede.',
  })
}
