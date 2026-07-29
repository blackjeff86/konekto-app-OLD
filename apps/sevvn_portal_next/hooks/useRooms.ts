import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { createRoom, deleteRoom, listRooms, updateRoom } from '@/lib/api/rooms'
import type { RoomInput } from '@/types/room'

export function useRooms() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['rooms', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listRooms(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const createMutation = useMutation({
    mutationFn: (input: RoomInput) => createRoom(hotelId!, token!, input),
    onSuccess: invalidate,
  })

  const updateMutation = useMutation({
    mutationFn: ({ roomId, input }: { roomId: string; input: RoomInput }) =>
      updateRoom(hotelId!, roomId, token!, input),
    onSuccess: invalidate,
  })

  const deleteMutation = useMutation({
    mutationFn: (roomId: string) => deleteRoom(hotelId!, roomId, token!),
    onSuccess: invalidate,
  })

  return {
    rooms: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    refetch: query.refetch,
    createRoom: createMutation.mutateAsync,
    updateRoom: updateMutation.mutateAsync,
    deleteRoom: deleteMutation.mutateAsync,
  }
}
