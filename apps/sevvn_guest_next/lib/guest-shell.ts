import { useMemo } from "react";
import type {
  GuestHotelConfig,
  GuestOrder,
  GuestService,
} from "@/lib/guest-types";
import type {
  ModuleDefinition,
  ModulesCatalogResponse,
} from "@/lib/module-catalog";
import {
  groupServicesByCatalog,
  resolveBottomNavModules,
  resolveHomeModules,
  resolveServicesMenuModules,
} from "@/lib/module-engine";

export type GuestLoadState =
  | { status: "idle" }
  | { status: "loading" }
  | {
      status: "ready";
      hotel: GuestHotelConfig;
      services: GuestService[];
      modulesCatalog: ModulesCatalogResponse;
    }
  | { status: "error"; message: string };

export type GuestViewState =
  | { kind: "home" }
  | { kind: "services" }
  | { kind: "bookings" }
  | { kind: "messages" }
  | { kind: "notices" }
  | { kind: "profile" }
  | { kind: "service-detail"; serviceId: string };

export type GuestOrdersState = {
  status: "idle" | "loading" | "ready" | "error";
  orders: GuestOrder[];
};

export type GuestServiceDetailState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "ready"; service: GuestService }
  | { status: "error"; message: string };

export type ResolvedModulesShape = {
  bottomNav: ModuleDefinition[];
  home: ModuleDefinition[];
  servicesMenu: ModuleDefinition[];
  groupedServices: ReturnType<typeof groupServicesByCatalog>;
};

export type GuestSurfaceRuntimeStatus = "live" | "gated" | "coming_soon";

export function useResolvedModules(
  loadState: GuestLoadState,
): ResolvedModulesShape | null {
  return useMemo(() => {
    if (loadState.status !== "ready") return null;

    const enabledModules = loadState.hotel.enabledModules ?? [];
    const catalog = loadState.modulesCatalog.modules;

    return {
      bottomNav: resolveBottomNavModules(enabledModules, catalog),
      home: resolveHomeModules(enabledModules, catalog),
      servicesMenu: resolveServicesMenuModules(enabledModules, catalog),
      groupedServices: groupServicesByCatalog({
        services: loadState.services,
        serviceGroups: loadState.modulesCatalog.serviceGroups,
        catalog,
      }),
    };
  }, [loadState]);
}

export function viewForModule(module: ModuleDefinition): GuestViewState {
  const route = module.screenId ?? module.id;

  if (route === "services") return { kind: "services" };
  if (route === "bookings") return { kind: "bookings" };
  if (route === "messages") return { kind: "messages" };
  if (route === "notices") return { kind: "notices" };
  if (route === "profile") return { kind: "profile" };
  return { kind: "home" };
}

export function activeModuleId(view: GuestViewState): string {
  if (view.kind === "home") return "hotel_info";
  if (view.kind === "services" || view.kind === "service-detail") {
    return "room_service";
  }
  if (view.kind === "bookings") return "restaurant";
  if (view.kind === "messages") return "messages";
  if (view.kind === "notices") return "basic_notifications";
  return "profile";
}

export function getModuleRuntimeStatus(
  module: ModuleDefinition,
): GuestSurfaceRuntimeStatus {
  const route = module.screenId ?? module.id;

  if (
    route === "home" ||
    route === "hotel_info" ||
    route === "services" ||
    route === "bookings" ||
    route === "messages" ||
    route === "notices" ||
    route === "profile" ||
    route.startsWith("service_")
  ) {
    return "live";
  }

  if (!module.implemented) {
    return "coming_soon";
  }

  return "gated";
}

export function supportsModuleNavigation(module: ModuleDefinition): boolean {
  return getModuleRuntimeStatus(module) === "live";
}

export function iconForModule(moduleId: string): string {
  switch (moduleId) {
    case "hotel_info":
      return "home";
    case "room_service":
      return "room_service";
    case "restaurant":
      return "calendar_month";
    case "concierge":
      return "concierge";
    case "basic_notifications":
      return "notifications";
    case "profile":
      return "person";
    case "messages":
      return "chat_bubble";
    case "wallet":
      return "account_balance_wallet";
    default:
      return "apps";
  }
}
