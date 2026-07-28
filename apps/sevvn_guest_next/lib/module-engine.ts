import type {
  ModuleDefinition,
  ModulePlacement,
  ServiceGroup,
} from "@/lib/module-catalog";
import type { GuestService, ResolvedHotelModule } from "@/lib/guest-types";

export function resolveModulesByPlacement({
  enabledModules,
  catalog,
  placement,
}: {
  enabledModules: ResolvedHotelModule[];
  catalog: ModuleDefinition[];
  placement: ModulePlacement;
}): ModuleDefinition[] {
  const catalogById = new Map(catalog.map((module) => [module.id, module]));

  return enabledModules
    .filter((module) => module.enabled)
    .map((module) => catalogById.get(module.id))
    .filter(
      (module): module is ModuleDefinition =>
        Boolean(module?.implemented && module.placement.includes(placement)),
    )
    .sort((a, b) => a.defaultOrder - b.defaultOrder);
}

export function resolveBottomNavModules(
  enabledModules: ResolvedHotelModule[],
  catalog: ModuleDefinition[],
): ModuleDefinition[] {
  return resolveModulesByPlacement({
    enabledModules,
    catalog,
    placement: "bottomNav",
  });
}

export function resolveHomeModules(
  enabledModules: ResolvedHotelModule[],
  catalog: ModuleDefinition[],
): ModuleDefinition[] {
  return resolveModulesByPlacement({
    enabledModules,
    catalog,
    placement: "home",
  });
}

export function resolveServicesMenuModules(
  enabledModules: ResolvedHotelModule[],
  catalog: ModuleDefinition[],
): ModuleDefinition[] {
  return resolveModulesByPlacement({
    enabledModules,
    catalog,
    placement: "servicesMenu",
  });
}

export interface GroupedServicesSection {
  id: string;
  title?: string;
  services: GuestService[];
}

export function groupServicesByCatalog({
  services,
  serviceGroups,
  catalog,
}: {
  services: GuestService[];
  serviceGroups: ServiceGroup[];
  catalog: ModuleDefinition[];
}): GroupedServicesSection[] {
  const catalogById = new Map(catalog.map((module) => [module.id, module]));
  const groupById = new Map(serviceGroups.map((group) => [group.id, group]));

  const ungrouped: GuestService[] = [];
  const grouped = new Map<string, GuestService[]>();

  for (const service of services) {
    const groupId = service.moduleId
      ? catalogById.get(service.moduleId)?.groupId
      : null;

    if (!groupId) {
      ungrouped.push(service);
      continue;
    }

    const items = grouped.get(groupId) ?? [];
    items.push(service);
    grouped.set(groupId, items);
  }

  const sections: GroupedServicesSection[] = [];

  if (ungrouped.length > 0) {
    sections.push({ id: "ungrouped", services: ungrouped });
  }

  const sortedGroups = [...serviceGroups].sort(
    (a, b) => a.defaultOrder - b.defaultOrder,
  );

  for (const group of sortedGroups) {
    const servicesInGroup = grouped.get(group.id) ?? [];
    if (servicesInGroup.length === 0) continue;

    sections.push({
      id: group.id,
      title: groupById.get(group.id)?.name ?? group.name,
      services: servicesInGroup,
    });
  }

  return sections;
}
