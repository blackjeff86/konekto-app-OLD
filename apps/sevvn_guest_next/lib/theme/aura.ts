import type { CSSProperties } from "react";
import type { GuestHotelConfig, GuestTemplateId } from "@/lib/guest-types";

const DEFAULT_AURA_PRIMARY = "#6750A4";
const DEFAULT_AURA_PRIMARY_STRONG = "#4F378A";
const DEFAULT_AURA_PRIMARY_SOFT = "#E9DDFF";
const DEFAULT_AURA_BACKGROUND = "#FDF7FF";
const DEFAULT_AURA_SURFACE_LOW = "#F8F2FA";

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const normalized = hex.trim().replace("#", "");
  if (!/^[0-9a-fA-F]{6}$/.test(normalized)) return null;

  return {
    r: Number.parseInt(normalized.slice(0, 2), 16),
    g: Number.parseInt(normalized.slice(2, 4), 16),
    b: Number.parseInt(normalized.slice(4, 6), 16),
  };
}

function rgba(hex: string, alpha: number): string {
  const rgb = hexToRgb(hex);
  if (!rgb) return hex;
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`;
}

function pickPrimary(hotel?: GuestHotelConfig): string {
  return hotel?.colorPalette?.primary?.trim() || DEFAULT_AURA_PRIMARY;
}

function pickSecondary(hotel?: GuestHotelConfig): string {
  return hotel?.colorPalette?.secondary?.trim() || DEFAULT_AURA_PRIMARY_STRONG;
}

export function resolveTemplateId(
  hotel?: GuestHotelConfig,
): GuestTemplateId | "aura" {
  return hotel?.template ?? "aura";
}

export function createAuraThemeStyle(
  hotel?: GuestHotelConfig,
): CSSProperties {
  const primary = pickPrimary(hotel);
  const secondary = pickSecondary(hotel);

  return {
    ["--aura-primary" as string]: primary,
    ["--aura-primary-strong" as string]: secondary,
    ["--aura-primary-soft" as string]: rgba(primary, 0.16),
    ["--aura-secondary-soft" as string]: rgba(secondary, 0.12),
    ["--aura-background" as string]: DEFAULT_AURA_BACKGROUND,
    ["--aura-surface-low" as string]: DEFAULT_AURA_SURFACE_LOW,
    ["--aura-shadow" as string]: `0 24px 64px ${rgba(primary, 0.18)}`,
  };
}
