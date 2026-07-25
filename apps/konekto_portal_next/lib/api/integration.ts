/** Portado de apps/konekto_portal/lib/data/integration_repository.dart. */
import { apiRequest, ApiError, API_BASE_URL } from './client'
import type { IntegrationStatus } from '@/types/integration'

export function getIntegrationStatus(hotelId: string, token: string): Promise<IntegrationStatus> {
  return apiRequest<IntegrationStatus>(`/api/hotels/${hotelId}/integration`, {
    token,
    errorMessage: 'Falha ao carregar a integração.',
  })
}

/** Devolve a chave em texto puro — o backend nunca mais consegue mostrá-la de novo (só o hash fica salvo). */
export async function rotateIntegrationApiKey(hotelId: string, token: string): Promise<string> {
  const body = await apiRequest<{ apiKey: string }>(`/api/hotels/${hotelId}/integration`, {
    method: 'POST',
    token,
    body: { action: 'rotate_key' },
    errorMessage: 'Falha ao gerar a chave.',
  })
  return body.apiKey
}

/**
 * Não usa `apiRequest` porque o 400 tem dois sub-casos distintos
 * (`unsafe_webhook_url` vs. URL genericamente inválida) que exigem
 * inspecionar o corpo do erro — o wrapper genérico só expõe o status.
 */
export async function setIntegrationWebhookUrl(
  hotelId: string,
  token: string,
  webhookUrl: string | null,
): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/hotels/${hotelId}/integration`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ webhookUrl }),
  })
  if (response.status === 404) {
    throw new ApiError('Gere uma chave de integração antes de configurar o webhook.', 404)
  }
  if (response.status === 400) {
    const body = (await response.json().catch(() => null)) as { error?: string } | null
    if (body?.error === 'unsafe_webhook_url') {
      throw new ApiError(
        'Essa URL não pode ser usada como webhook — aponta pra um endereço interno/privado.',
        400,
      )
    }
    throw new ApiError('Essa URL de webhook não parece válida.', 400)
  }
  if (!response.ok) {
    throw new ApiError(`Falha ao salvar a URL do webhook (status ${response.status}).`, response.status)
  }
}
