import { useMutation, useQuery } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { listCustomers, sendPromo } from '@/lib/api/customers'

export function useCustomers() {
  const { session, token } = useAuth()
  const hotelId = session?.hotelId

  const query = useQuery({
    queryKey: ['customers', hotelId],
    queryFn: () => listCustomers(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const sendPromoMutation = useMutation({
    mutationFn: ({
      documentNumber,
      couponId,
      message,
    }: {
      documentNumber: string
      couponId: string
      message?: string
    }) => sendPromo(hotelId!, documentNumber, token!, couponId, message),
  })

  return {
    customers: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    sendPromo: sendPromoMutation.mutateAsync,
  }
}
