import { useQuery } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { getDashboardStats } from '@/lib/api/dashboard'

export function useDashboardStats() {
  const { session, token } = useAuth()
  const hotelId = session?.hotelId

  const query = useQuery({
    queryKey: ['dashboard-stats', hotelId],
    queryFn: () => getDashboardStats(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  return {
    stats: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
  }
}
