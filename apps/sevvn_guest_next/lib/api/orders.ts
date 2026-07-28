import { apiRequest } from "@/lib/api/client";
import type { GuestOrder } from "@/lib/guest-types";

export function getGuestOrders(token: string): Promise<GuestOrder[]> {
  return apiRequest<GuestOrder[]>("/api/orders", {
    token,
    errorMessage: "Falha ao carregar os pedidos do hospede.",
  });
}

export class GuestOrderActionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "GuestOrderActionError";
  }
}

export function createGuestOrder({
  token,
  serviceId,
  serviceItemId,
  quantity,
  note,
  consumptionReport,
  scheduledFor,
  tableTypeId,
}: {
  token: string;
  serviceId: string;
  serviceItemId?: string;
  quantity?: number;
  note?: string;
  consumptionReport?: boolean;
  scheduledFor?: string;
  tableTypeId?: string;
}): Promise<GuestOrder> {
  return apiRequest<GuestOrder>("/api/orders", {
    method: "POST",
    token,
    body: JSON.stringify({
      serviceId,
      ...(serviceItemId ? { serviceItemId } : {}),
      quantity: quantity ?? 1,
      ...(note?.trim() ? { note: note.trim() } : {}),
      ...(consumptionReport ? { consumptionReport: true } : {}),
      ...(scheduledFor ? { scheduledFor } : {}),
      ...(tableTypeId ? { tableTypeId } : {}),
    }),
    errorMessage: "Falha ao enviar o pedido do hospede.",
  }).catch((error: unknown) => {
    if (
      typeof error === "object" &&
      error !== null &&
      "payload" in error &&
      typeof (error as { payload?: unknown }).payload === "object" &&
      (error as { payload?: { error?: string } }).payload?.error
    ) {
      const code = (error as { payload?: { error?: string } }).payload?.error;
      throw new GuestOrderActionError(
        code === "service_closed"
          ? "O servico esta fechado neste momento."
          : code === "guest_consumption_reports_disabled"
            ? "Este hotel nao permite informar consumo de frigobar pelo app."
          : code === "invalid_schedule"
            ? "O horario escolhido nao esta disponivel para este servico."
          : code === "slot_full"
            ? "Esse horario acabou de lotar. Escolha outro slot disponivel."
          : code === "table_full"
            ? "Nao ha mais mesas disponiveis para essa configuracao."
            : code === "invalid_request"
              ? "Revise a data, o horario e a configuracao da reserva."
          : "Nao foi possivel concluir o pedido agora.",
      );
    }

    throw new GuestOrderActionError("Nao foi possivel concluir o pedido agora.");
  });
}
