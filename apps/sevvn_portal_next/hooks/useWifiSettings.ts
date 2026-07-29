import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { getWifiSettings, updateWifiSettings } from '@/lib/api/hotelConfig'

export function useWifiSettings() {
  const { session, token } = useAuth()
  const queryClient = useQueryClient()
  const hotelId = session?.hotelId
  const queryKey = ['wifi-settings', hotelId] as const

  const query = useQuery({
    queryKey,
    queryFn: () => getWifiSettings(hotelId!, token!),
    enabled: Boolean(hotelId && token),
  })

  const updateMutation = useMutation({
    mutationFn: ({ networkName, password }: { networkName: string; password: string }) =>
      updateWifiSettings(hotelId!, token!, networkName, password),
    onSuccess: () => queryClient.invalidateQueries({ queryKey }),
  })

  return {
    wifi: query.data ?? { networkName: '', password: '' },
    isLoading: query.isLoading,
    error: query.error,
    updateWifi: updateMutation.mutateAsync,
  }
}
