import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { getPaymentAccount, setPaymentRecipientId } from '@/lib/api/payments'

/** Wrapper de React Query sobre lib/api/payments.ts. */
export function usePaymentAccount() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['payment-account', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getPaymentAccount(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const setRecipientMutation = useMutation({
    mutationFn: (recipientId: string) => setPaymentRecipientId(hotelId!, token!, recipientId),
    onSuccess: (account) => queryClient.setQueryData(queryKey, account),
  })

  return {
    account: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    setRecipientId: setRecipientMutation.mutateAsync,
  }
}
