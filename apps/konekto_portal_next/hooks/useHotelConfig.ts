import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import {
  getHotelConfig,
  updateBranding,
  updateModuleConfiguration,
  updateModuleEnabled,
  updatePromoImages,
  updateTemplate,
  type BrandingInput,
} from '@/lib/api/hotelConfig'
import type { ModuleConfigurationInput } from '@/types/hotelConfig'

/** Marca/Aparência do hotel (nome, logo, endereço, carrossel, template) — Fase 5. */
export function useHotelConfig() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['hotel-config', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getHotelConfig(hotelId!, token!),
    enabled: Boolean(hotelId && token),
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

  const updateModuleConfigurationMutation = useMutation({
    mutationFn: ({ moduleId, input }: { moduleId: string; input: ModuleConfigurationInput }) =>
      updateModuleConfiguration(hotelId!, token!, moduleId, input),
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
    updateModuleConfiguration: updateModuleConfigurationMutation.mutateAsync,
  }
}
