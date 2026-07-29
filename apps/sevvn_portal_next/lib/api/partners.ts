/** Portado de apps/konekto_portal/lib/data/partners_repository.dart. */
import { apiRequest } from './client'
import type { Partner, PartnerInput } from '@/types/partner'

export function listPartners(hotelId: string, token: string): Promise<Partner[]> {
  return apiRequest<Partner[]>(`/api/hotels/${hotelId}/partners`, {
    token,
    errorMessage: 'Falha ao carregar parceiros.',
  })
}

export function createPartner(hotelId: string, token: string, input: PartnerInput): Promise<Partner> {
  return apiRequest<Partner>(`/api/hotels/${hotelId}/partners`, {
    method: 'POST',
    token,
    body: input,
    errorMessage: 'Falha ao criar parceiro.',
  })
}

export function updatePartner(
  hotelId: string,
  partnerId: string,
  token: string,
  input: PartnerInput,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/partners/${partnerId}`, {
    method: 'PATCH',
    token,
    body: input,
    errorMessage: 'Falha ao atualizar parceiro.',
  })
}

export function deletePartner(hotelId: string, partnerId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/partners/${partnerId}`, {
    method: 'DELETE',
    token,
    conflictMessage: 'Esse parceiro está vinculado a itens do catálogo — desvincule antes de remover.',
    errorMessage: 'Falha ao remover parceiro.',
  })
}
