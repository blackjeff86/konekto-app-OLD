import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  createCoupon,
  deleteCoupon,
  listCoupons,
  setCouponEnabled,
  updateCoupon,
} from '@/lib/api/coupons'
import type { CouponInput } from '@/types/coupon'

/**
 * Wrapper de React Query sobre lib/api/coupons.ts — hook canônico usado
 * como template pros próximos 8 recursos (ver plano de migração, Fase 1).
 */
export function useCoupons() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['coupons', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => listCoupons(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const createMutation = useMutation({
    mutationFn: (input: CouponInput) => createCoupon(hotelId!, token!, input),
    onSuccess: invalidate,
  })

  const updateMutation = useMutation({
    mutationFn: ({ couponId, input }: { couponId: string; input: CouponInput }) =>
      updateCoupon(hotelId!, couponId, token!, input),
    onSuccess: invalidate,
  })

  const setEnabledMutation = useMutation({
    mutationFn: ({ couponId, enabled }: { couponId: string; enabled: boolean }) =>
      setCouponEnabled(hotelId!, couponId, token!, enabled),
    onSuccess: invalidate,
  })

  const deleteMutation = useMutation({
    mutationFn: (couponId: string) => deleteCoupon(hotelId!, couponId, token!),
    onSuccess: invalidate,
  })

  return {
    coupons: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createCoupon: createMutation.mutateAsync,
    updateCoupon: updateMutation.mutateAsync,
    setCouponEnabled: setEnabledMutation.mutateAsync,
    deleteCoupon: deleteMutation.mutateAsync,
  }
}
