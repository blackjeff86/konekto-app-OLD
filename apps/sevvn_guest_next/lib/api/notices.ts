import { apiRequest } from "@/lib/api/client";
import type { GuestNotice } from "@/lib/guest-types";

export function getGuestNotices(token: string): Promise<GuestNotice[]> {
  return apiRequest<GuestNotice[]>("/api/guest/notices", {
    token,
    errorMessage: "Falha ao carregar os avisos da estadia.",
  });
}
