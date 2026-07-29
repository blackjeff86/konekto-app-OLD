import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { listOrders, updateOrderStatus } from '@/lib/api/orders'
import type { OrderStatus } from '@/types/order'

const ORDER_POLL_INTERVAL_MS = 5000

/**
 * Wrapper de React Query sobre lib/api/orders.ts. Usa a mesma queryKey que
 * useOrderNotifications (['orders', hotelId]) — como o layout autenticado
 * já mantém essa chave viva com polling de 5s, esta tela só reaproveita o
 * cache/poll compartilhado em vez de duplicar a requisição.
 */
export function useOrders() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['orders', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listOrders(hotelId!, token!),
    enabled: Boolean(hotelId && token),
    refetchInterval: ORDER_POLL_INTERVAL_MS,
  })

  const updateStatusMutation = useMutation({
    mutationFn: ({ orderId, status }: { orderId: string; status: OrderStatus }) =>
      updateOrderStatus(hotelId!, orderId, token!, status),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  return {
    orders: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    updateStatus: updateStatusMutation.mutateAsync,
  }
}
