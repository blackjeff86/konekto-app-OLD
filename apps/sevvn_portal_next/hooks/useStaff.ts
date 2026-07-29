import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { createStaffInvite, listStaff, revokeStaff } from '@/lib/api/staff'

/** Wrapper de React Query sobre lib/api/staff.ts. */
export function useStaff() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['staff', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listStaff(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const revokeMutation = useMutation({
    mutationFn: (staffId: string) => revokeStaff(hotelId!, staffId, token!),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  const inviteMutation = useMutation({
    mutationFn: () => createStaffInvite(token!),
  })

  return {
    members: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    revokeStaff: revokeMutation.mutateAsync,
    createInvite: inviteMutation.mutateAsync,
  }
}
