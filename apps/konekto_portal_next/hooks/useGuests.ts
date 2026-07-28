import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  createGuest,
  getGuest,
  listGuests,
  lookupGuestByDocument,
  regenerateGuestAccessCode,
  revokeGuest,
  updateGuest,
} from '@/lib/api/guests'
import type { GuestEditInput, NewGuestInput } from '@/types/guest'

/** Wrapper de React Query sobre lib/api/guests.ts. */
export function useGuests() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['guests', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listGuests(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const createMutation = useMutation({
    mutationFn: (input: NewGuestInput) => createGuest(hotelId!, token!, input),
    onSuccess: invalidate,
  })

  const revokeMutation = useMutation({
    mutationFn: (guestId: string) => revokeGuest(hotelId!, guestId, token!),
    onSuccess: invalidate,
  })

  return {
    guests: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createGuest: createMutation.mutateAsync,
    revokeGuest: revokeMutation.mutateAsync,
  }
}

/** Um único hóspede (endpoint de detalhe, inclui `orders`) + edição. */
export function useGuest(guestId: string) {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['guests', hotelId, guestId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getGuest(hotelId!, guestId, token!),
    enabled: Boolean(hotelId && token && guestId),
  })

  const updateMutation = useMutation({
    mutationFn: (input: GuestEditInput) => updateGuest(hotelId!, guestId, token!, input),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  const revokeMutation = useMutation({
    mutationFn: () => revokeGuest(hotelId!, guestId, token!),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  const regenerateAccessCodeMutation = useMutation({
    mutationFn: () => regenerateGuestAccessCode(hotelId!, guestId, token!),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  return {
    guest: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    updateGuest: updateMutation.mutateAsync,
    regenerateAccessCode: regenerateAccessCodeMutation.mutateAsync,
    revokeGuest: revokeMutation.mutateAsync,
  }
}

/** Busca por documento sob demanda (não é auto-fetch) — usada ao ocupar um quarto. */
export function useGuestLookup() {
  const { session, token } = useAuth()
  const hotelId = session?.hotelId

  const mutation = useMutation({
    mutationFn: (documentNumber: string) => lookupGuestByDocument(hotelId!, token!, documentNumber),
  })

  return {
    lookup: mutation.mutateAsync,
    isLoading: mutation.isPending,
  }
}
