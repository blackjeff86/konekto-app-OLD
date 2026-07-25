import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  createItem,
  createTableType,
  deleteItem,
  deleteTableType,
  getService,
  updateItem,
  updateTableType,
  type TableTypeInput,
} from '@/lib/api/services'
import type { ServiceItemInput } from '@/types/service'

/**
 * Wrapper de React Query sobre lib/api/services.ts pra um único serviço —
 * usado na tela de gestão de itens (equivalente a ServiceItemsPage).
 */
export function useService(serviceId: string) {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['service', hotelId, serviceId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getService(hotelId!, serviceId),
    enabled: Boolean(hotelId && serviceId),
  })

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey })
    queryClient.invalidateQueries({ queryKey: ['services', hotelId] })
  }

  const createItemMutation = useMutation({
    mutationFn: (item: ServiceItemInput) => createItem(hotelId!, serviceId, token!, item),
    onSuccess: invalidate,
  })

  const updateItemMutation = useMutation({
    mutationFn: ({ itemId, item }: { itemId: string; item: ServiceItemInput }) =>
      updateItem(hotelId!, serviceId, itemId, token!, item),
    onSuccess: invalidate,
  })

  const deleteItemMutation = useMutation({
    mutationFn: (itemId: string) => deleteItem(hotelId!, serviceId, itemId, token!),
    onSuccess: invalidate,
  })

  const createTableTypeMutation = useMutation({
    mutationFn: (input: TableTypeInput) => createTableType(hotelId!, serviceId, token!, input),
    onSuccess: invalidate,
  })

  const updateTableTypeMutation = useMutation({
    mutationFn: ({ tableTypeId, input }: { tableTypeId: string; input: TableTypeInput }) =>
      updateTableType(hotelId!, serviceId, tableTypeId, token!, input),
    onSuccess: invalidate,
  })

  const deleteTableTypeMutation = useMutation({
    mutationFn: (tableTypeId: string) => deleteTableType(hotelId!, serviceId, tableTypeId, token!),
    onSuccess: invalidate,
  })

  return {
    service: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    createItem: createItemMutation.mutateAsync,
    updateItem: updateItemMutation.mutateAsync,
    deleteItem: deleteItemMutation.mutateAsync,
    createTableType: createTableTypeMutation.mutateAsync,
    updateTableType: updateTableTypeMutation.mutateAsync,
    deleteTableType: deleteTableTypeMutation.mutateAsync,
  }
}
