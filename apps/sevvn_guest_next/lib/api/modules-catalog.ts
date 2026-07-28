import { apiRequest } from "@/lib/api/client";
import type { ModulesCatalogResponse } from "@/lib/module-catalog";

export function getModulesCatalog(): Promise<ModulesCatalogResponse> {
  return apiRequest<ModulesCatalogResponse>("/api/modules-catalog", {
    errorMessage: "Falha ao carregar o catalogo de modulos.",
  });
}
