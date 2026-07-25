import { useQuery } from '@tanstack/react-query'
import { getModulesCatalog } from '@/lib/api/modulesCatalog'

/** Catálogo público de módulos — muda raramente, cache longo (React Query
 *  já deduplica entre telas que usam este hook na mesma sessão). */
export function useModulesCatalog() {
  const query = useQuery({
    queryKey: ['modules-catalog'],
    queryFn: getModulesCatalog,
    staleTime: 5 * 60 * 1000,
  })

  return {
    modules: query.data?.modules ?? [],
    serviceGroups: query.data?.serviceGroups ?? [],
    planPresets: query.data?.planPresets ?? [],
    isLoading: query.isLoading,
    error: query.error,
  }
}
