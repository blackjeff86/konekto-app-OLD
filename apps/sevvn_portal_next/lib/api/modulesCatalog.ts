import { apiRequest } from './client'
import type { ModulesCatalogResponse } from '@/types/moduleCatalog'

/** Catálogo público de módulos — mesmo endpoint que konekto_admin e o app
 *  do hóspede consultam, nenhum mantém cópia local (ver header doc de
 *  apps/sevvn_api/lib/module-catalog.ts). Sem token: rota pública. */
export function getModulesCatalog(): Promise<ModulesCatalogResponse> {
  return apiRequest<ModulesCatalogResponse>('/api/modules-catalog', {
    errorMessage: 'Falha ao carregar o catálogo de módulos.',
  })
}

