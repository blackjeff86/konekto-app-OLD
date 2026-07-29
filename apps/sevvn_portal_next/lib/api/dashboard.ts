/** Portado de apps/konekto_portal/lib/data/dashboard_repository.dart. */
import { apiRequest } from './client'
import type { DashboardStats } from '@/types/dashboardStats'

export function getDashboardStats(hotelId: string, token: string): Promise<DashboardStats> {
  return apiRequest<DashboardStats>(`/api/hotels/${hotelId}/dashboard/stats`, {
    token,
    errorMessage: 'Falha ao carregar estatísticas.',
  })
}
