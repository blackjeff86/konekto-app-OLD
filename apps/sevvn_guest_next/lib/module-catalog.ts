export type ModuleCategory =
  | "core"
  | "hospitalidade"
  | "financeiro"
  | "experiencia"
  | "comunicacao";

export type ModulePlacement = "home" | "bottomNav" | "servicesMenu" | "settings";
export type ModuleOperationMode =
  | "standalone"
  | "hybrid"
  | "integration_required";

export interface ModuleDefinition {
  id: string;
  name: string;
  description: string;
  category: ModuleCategory;
  groupId?: string;
  icon: string;
  placement: ModulePlacement[];
  screenId?: string;
  defaultOrder: number;
  dependencies: string[];
  operationMode: ModuleOperationMode;
  implemented: boolean;
  configSchemaId?: string;
}

export interface ServiceGroup {
  id: string;
  name: string;
  defaultOrder: number;
}

export interface PlanPreset {
  id: string;
  name: string;
  moduleIds: string[];
  templateIds: string[];
}

export interface ModulesCatalogResponse {
  modules: ModuleDefinition[];
  serviceGroups: ServiceGroup[];
  planPresets: PlanPreset[];
}
