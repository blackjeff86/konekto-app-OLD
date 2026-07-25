import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { getServicesPageBannerImageUrl, updateServicesPageBannerImageUrl } from '@/lib/api/hotelConfig'

/** Banner do topo da tela "Serviços" no app do hóspede — HotelContent separado de branding. */
export function useServicesPageBanner() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['services-page-banner', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getServicesPageBannerImageUrl(hotelId!),
    enabled: Boolean(hotelId),
  })

  const updateMutation = useMutation({
    mutationFn: (imageUrl: string) => updateServicesPageBannerImageUrl(hotelId!, token!, imageUrl),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  return {
    bannerImageUrl: query.data ?? '',
    isLoading: query.isLoading,
    error: query.error,
    updateBanner: updateMutation.mutateAsync,
  }
}
