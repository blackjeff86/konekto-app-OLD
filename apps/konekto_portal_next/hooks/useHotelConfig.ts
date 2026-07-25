import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  getHotelConfig,
  updateBranding,
  updateInfra,
  updatePromoImages,
  type BrandingInput,
} from '@/lib/api/hotelConfig'

/** Marca/Aparência do hotel (nome, logo, endereço, carrossel, infra) — Fase 5. */
export function useHotelConfig() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['hotel-config', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getHotelConfig(hotelId!),
    enabled: Boolean(hotelId),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const updateBrandingMutation = useMutation({
    mutationFn: (input: BrandingInput) => updateBranding(hotelId!, token!, input),
    onSuccess: invalidate,
  })

  const updatePromoImagesMutation = useMutation({
    mutationFn: ({ images, carouselHeight }: { images: string[]; carouselHeight?: number }) =>
      updatePromoImages(hotelId!, token!, images, carouselHeight),
    onSuccess: invalidate,
  })

  const updateInfraMutation = useMutation({
    mutationFn: (infra: string) => updateInfra(hotelId!, token!, infra),
    onSuccess: invalidate,
  })

  return {
    config: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    updateBranding: updateBrandingMutation.mutateAsync,
    updatePromoImages: updatePromoImagesMutation.mutateAsync,
    updateInfra: updateInfraMutation.mutateAsync,
  }
}
