import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { getIntegrationStatus, rotateIntegrationApiKey, setIntegrationWebhookUrl } from '@/lib/api/integration'

/** Wrapper de React Query sobre lib/api/integration.ts. */
export function useIntegration() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['integration', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getIntegrationStatus(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const rotateKeyMutation = useMutation({
    mutationFn: () => rotateIntegrationApiKey(hotelId!, token!),
    onSuccess: invalidate,
  })

  const setWebhookMutation = useMutation({
    mutationFn: (webhookUrl: string | null) => setIntegrationWebhookUrl(hotelId!, token!, webhookUrl),
    onSuccess: invalidate,
  })

  return {
    status: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    rotateApiKey: rotateKeyMutation.mutateAsync,
    setWebhookUrl: setWebhookMutation.mutateAsync,
  }
}
