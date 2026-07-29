import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  changeRoom,
  closeStay,
  extendStay,
  getStay,
  markMessagesRead,
  sendMessage,
} from '@/lib/api/stays'
import { recordConsumption } from '@/lib/api/orders'

/** Detalhe de uma única estadia + ações (Fase 3: Quartos e Estadias). */
export function useStay(stayId: string) {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['stays', hotelId, stayId] as const

  const query = useQuery({
    queryKey,
    queryFn: async () => {
      const stay = await getStay(hotelId!, stayId, token!)
      // Não crítico — se falhar, o badge de mensagens não lidas só demora mais pra zerar.
      markMessagesRead(hotelId!, stayId, token!).catch(() => {})
      return stay
    },
    enabled: Boolean(hotelId && token && stayId),
  })

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey })
    queryClient.invalidateQueries({ queryKey: ['rooms', hotelId] })
  }

  const extendMutation = useMutation({
    mutationFn: (checkOutDate: string) => extendStay(hotelId!, stayId, token!, checkOutDate),
    onSuccess: invalidate,
  })

  const changeRoomMutation = useMutation({
    mutationFn: (roomId: string) => changeRoom(hotelId!, stayId, token!, roomId),
    onSuccess: invalidate,
  })

  const closeMutation = useMutation({
    mutationFn: () => closeStay(hotelId!, stayId, token!),
    onSuccess: invalidate,
  })

  const sendMessageMutation = useMutation({
    mutationFn: (message: string) => sendMessage(hotelId!, stayId, token!, message),
    onSuccess: invalidate,
  })

  const recordConsumptionMutation = useMutation({
    mutationFn: (input: { guestId: string; serviceItemId: string; quantity: number }) =>
      recordConsumption(hotelId!, stayId, token!, input.guestId, input.serviceItemId, input.quantity),
    onSuccess: invalidate,
  })

  return {
    stay: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    extendStay: extendMutation.mutateAsync,
    changeRoom: changeRoomMutation.mutateAsync,
    closeStay: closeMutation.mutateAsync,
    sendMessage: sendMessageMutation.mutateAsync,
    recordConsumption: recordConsumptionMutation.mutateAsync,
  }
}
