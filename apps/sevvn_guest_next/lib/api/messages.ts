import { apiRequest } from "@/lib/api/client";
import type { GuestMessage } from "@/lib/guest-types";

export function getGuestMessages(token: string): Promise<GuestMessage[]> {
  return apiRequest<GuestMessage[]>("/api/guest/messages", {
    token,
    errorMessage: "Falha ao carregar as mensagens da hospedagem.",
  });
}

export function sendGuestMessage(
  token: string,
  message: string,
): Promise<GuestMessage> {
  return apiRequest<GuestMessage>("/api/guest/messages", {
    method: "POST",
    token,
    body: JSON.stringify({ message }),
    errorMessage: "Falha ao enviar a mensagem para a equipe do hotel.",
  });
}
