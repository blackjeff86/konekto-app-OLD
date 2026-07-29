import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { createPartner, deletePartner, listPartners, updatePartner } from '@/lib/api/partners'
import type { PartnerInput } from '@/types/partner'

/** Wrapper de React Query sobre lib/api/partners.ts — clone de useCoupons. */
export function usePartners() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['partners', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listPartners(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const createMutation = useMutation({
    mutationFn: (input: PartnerInput) => createPartner(hotelId!, token!, input),
    onSuccess: invalidate,
  })

  const updateMutation = useMutation({
    mutationFn: ({ partnerId, input }: { partnerId: string; input: PartnerInput }) =>
      updatePartner(hotelId!, partnerId, token!, input),
    onSuccess: invalidate,
  })

  const deleteMutation = useMutation({
    mutationFn: (partnerId: string) => deletePartner(hotelId!, partnerId, token!),
    onSuccess: invalidate,
  })

  return {
    partners: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createPartner: createMutation.mutateAsync,
    updatePartner: updateMutation.mutateAsync,
    deletePartner: deleteMutation.mutateAsync,
  }
}
