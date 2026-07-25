import { useQuery } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { listMinibarItems } from '@/lib/api/services'

/** Itens marcados como frigobar, usado no diálogo "Lançar consumo" (Fase 3). */
export function useMinibarItems() {
  const { session } = useAuth()
  const hotelId = session?.hotelId

  const query = useQuery({
    queryKey: ['minibar-items', hotelId],
    queryFn: () => listMinibarItems(hotelId!),
    enabled: Boolean(hotelId),
  })

  return {
    minibarItems: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
  }
}
