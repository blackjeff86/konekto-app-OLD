import { apiRequest } from "@/lib/api/client";
import type { GuestClaimResponse } from "@/lib/guest-types";

export function claimGuestAccess(code: string): Promise<GuestClaimResponse> {
  return apiRequest<GuestClaimResponse>("/api/guest/claim", {
    method: "POST",
    body: JSON.stringify({ code }),
    errorMessage: "Falha ao validar o codigo de acesso do hospede.",
  });
}
