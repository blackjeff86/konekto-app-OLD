import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  getHotelConfig,
  updateBranding,
  updateModuleEnabled,
  updatePromoImages,
  updateTemplate,
  type BrandingInput,
} from '@/lib/api/hotelConfig'

/** Marca/Aparência do hotel (nome, logo, endereço, carrossel, template) — Fase 5. */
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

  const updateTemplateMutation = useMutation({
    mutationFn: (template: string) => updateTemplate(hotelId!, token!, template),
    onSuccess: invalidate,
  })

  const updateModuleEnabledMutation = useMutation({
    mutationFn: ({ moduleId, enabled }: { moduleId: string; enabled: boolean }) =>
      updateModuleEnabled(hotelId!, token!, moduleId, enabled),
    onSuccess: invalidate,
  })

  return {
    config: query.data ?? null,
    isLoading: query.isLoading,
    error: query.error,
    updateBranding: updateBrandingMutation.mutateAsync,
    updatePromoImages: updatePromoImagesMutation.mutateAsync,
    updateTemplate: updateTemplateMutation.mutateAsync,
    updateModuleEnabled: updateModuleEnabledMutation.mutateAsync,
  }
}
