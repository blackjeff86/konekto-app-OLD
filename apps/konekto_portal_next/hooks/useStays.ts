import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { createStay, listStays } from '@/lib/api/stays'
import type { NewStayInput } from '@/types/stay'

export function useStays() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId

  const query = useQuery({
    queryKey: ['stays', hotelId],
    queryFn: () => listStays(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const createMutation = useMutation({
    mutationFn: (input: NewStayInput) => createStay(hotelId!, token!, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stays', hotelId] })
      queryClient.invalidateQueries({ queryKey: ['rooms', hotelId] })
    },
  })

  return {
    stays: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createStay: createMutation.mutateAsync,
  }
}
