/** Espelha apps/konekto_api/lib/module-catalog.ts — servido via
 *  GET /api/modules-catalog, nunca hardcoded aqui (esse é o ponto: nenhum
 *  app mantém cópia local da lista de módulos). */
export type ModuleCategory = 'core' | 'hospitalidade' | 'financeiro' | 'experiencia' | 'comunicacao'
export type ModulePlacement = 'home' | 'bottomNav' | 'servicesMenu' | 'settings'

export interface ModuleDefinition {
  id: string
  name: string
  description: string
  category: ModuleCategory
  groupId?: string
  icon: string
  placement: ModulePlacement[]
  screenId?: string
  defaultOrder: number
  dependencies: string[]
  implemented: boolean
  configSchemaId?: string
}

export interface ServiceGroup {
  id: string
  name: string
  defaultOrder: number
}

export interface PlanPreset {
  id: string
  name: string
  moduleIds: string[]
  templateIds: string[]
}

export interface ModulesCatalogResponse {
  modules: ModuleDefinition[]
  serviceGroups: ServiceGroup[]
  planPresets: PlanPreset[]
}

export const MODULE_CATEGORY_LABELS: Record<ModuleCategory, string> = {
  core: 'Núcleo da plataforma',
  hospitalidade: 'Hospitalidade',
  financeiro: 'Financeiro',
  experiencia: 'Experiência',
  comunicacao: 'Comunicação',
}
