import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  createService,
  deleteService,
  listServices,
  updateService,
  type CreateServiceInput,
  type UpdateServiceInput,
} from '@/lib/api/services'

/** Wrapper de React Query sobre lib/api/services.ts — lista + CRUD de serviços. */
export function useServices() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['services', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listServices(hotelId!),
    enabled: Boolean(hotelId),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const createMutation = useMutation({
    mutationFn: (input: CreateServiceInput) => createService(hotelId!, token!, input),
    onSuccess: invalidate,
  })

  const updateMutation = useMutation({
    mutationFn: ({ serviceId, input }: { serviceId: string; input: UpdateServiceInput }) =>
      updateService(hotelId!, serviceId, token!, input),
    onSuccess: invalidate,
  })

  const deleteMutation = useMutation({
    mutationFn: (serviceId: string) => deleteService(hotelId!, serviceId, token!),
    onSuccess: invalidate,
  })

  return {
    services: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createService: createMutation.mutateAsync,
    updateService: updateMutation.mutateAsync,
    deleteService: deleteMutation.mutateAsync,
  }
}
