import { apiRequest } from "@/lib/api/client";
import type {
  GuestClaimBranding,
  GuestHotelConfig,
  GuestItemAvailabilityResponse,
  GuestService,
  GuestTableAvailabilityResponse,
} from "@/lib/guest-types";

export function resolveGuestBranding(host: string): Promise<GuestClaimBranding> {
  const search = new URLSearchParams({ host });

  return apiRequest<GuestClaimBranding>(`/api/public/guest-branding/resolve?${search.toString()}`, {
    errorMessage: "Falha ao carregar a identidade do hotel.",
  });
}

export function getGuestHotelConfig(hotelId: string): Promise<GuestHotelConfig> {
  return apiRequest<GuestHotelConfig>(`/api/hotels/${hotelId}`, {
    errorMessage: "Falha ao carregar a configuracao do hotel.",
  });
}

export function getGuestServices(hotelId: string): Promise<GuestService[]> {
  return apiRequest<GuestService[]>(`/api/hotels/${hotelId}/services`, {
    errorMessage: "Falha ao carregar a lista de servicos.",
  });
}

export function getGuestService(
  hotelId: string,
  serviceId: string,
): Promise<GuestService> {
  return apiRequest<GuestService>(
    `/api/hotels/${hotelId}/services/${serviceId}`,
    {
      errorMessage: "Falha ao carregar os detalhes do servico.",
    },
  );
}

export function getGuestRestaurantTableAvailability(
  hotelId: string,
  serviceId: string,
  scheduledFor: string,
): Promise<GuestTableAvailabilityResponse> {
  const search = new URLSearchParams({ scheduledFor });

  return apiRequest<GuestTableAvailabilityResponse>(
    `/api/hotels/${hotelId}/services/${serviceId}/table-availability?${search.toString()}`,
    {
      errorMessage: "Falha ao carregar a disponibilidade de mesas.",
    },
  );
}

export function getGuestItemAvailability(
  hotelId: string,
  serviceId: string,
  itemId: string,
  date: string,
): Promise<GuestItemAvailabilityResponse> {
  const search = new URLSearchParams({ date });

  return apiRequest<GuestItemAvailabilityResponse>(
    `/api/hotels/${hotelId}/services/${serviceId}/items/${itemId}/availability?${search.toString()}`,
    {
      errorMessage: "Falha ao carregar a disponibilidade do agendamento.",
    },
  );
}
