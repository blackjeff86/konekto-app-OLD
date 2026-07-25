/** Portado de apps/konekto_portal/lib/data/staff_invite_repository.dart. */
import { apiRequest } from './client'
import type { StaffMember } from '@/types/staff'

export function listStaff(hotelId: string, token: string): Promise<StaffMember[]> {
  return apiRequest<StaffMember[]>(`/api/hotels/${hotelId}/staff`, {
    token,
    errorMessage: 'Falha ao carregar a equipe.',
  })
}

export function revokeStaff(hotelId: string, staffId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/staff/${staffId}`, {
    method: 'DELETE',
    token,
    conflictMessage: 'Não é possível remover o único gerente do hotel.',
    errorMessage: 'Falha ao revogar acesso.',
  })
}

/** Não depende de hotelId — a conta convidada herda o hotel do próprio staff logado no backend. */
export async function createStaffInvite(token: string): Promise<string> {
  const body = await apiRequest<{ code: string }>('/api/staff-invites', {
    method: 'POST',
    token,
    errorMessage: 'Falha ao gerar convite.',
  })
  return body.code
}
