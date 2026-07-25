import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { listSupportMessages, markSupportMessagesRead, sendSupportMessage } from '@/lib/api/support'

/** Conversa direta do hotel com a equipe do Konekto (Fase 4). */
export function useSupport() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['support-messages', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: async () => {
      const messages = await listSupportMessages(hotelId!, token!)
      // Não crítico — se falhar, o badge de não lidas só demora mais pra zerar.
      markSupportMessagesRead(hotelId!, token!).catch(() => {})
      return messages
    },
    enabled: Boolean(hotelId && token),
  })

  const sendMutation = useMutation({
    mutationFn: (message: string) => sendSupportMessage(hotelId!, token!, message),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  return {
    messages: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    sendMessage: sendMutation.mutateAsync,
  }
}
