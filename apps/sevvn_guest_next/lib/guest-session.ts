import type { GuestClaimGuest } from "@/lib/guest-types";

const STORAGE_KEY = "sevvn_guest_session";

export interface GuestSession {
  token: string;
  guest: GuestClaimGuest;
}

export function loadGuestSession(): GuestSession | null {
  if (typeof window === "undefined") return null;

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as GuestSession;
  } catch {
    return null;
  }
}

export function saveGuestSession(session: GuestSession): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
}

export function clearGuestSession(): void {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem(STORAGE_KEY);
}
