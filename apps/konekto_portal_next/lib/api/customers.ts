/** Portado de apps/konekto_portal/lib/data/customers_repository.dart. */
import { API_BASE_URL, ApiError, apiRequest } from './client'
import type { Customer } from '@/types/customer'

export function listCustomers(hotelId: string, token: string): Promise<Customer[]> {
  return apiRequest<Customer[]>(`/api/hotels/${hotelId}/customers`, {
    token,
    errorMessage: 'Falha ao carregar clientes.',
  })
}

const SEND_PROMO_ERROR_MESSAGES: Record<string, string> = {
  customer_no_email: 'Esse cliente não tem e-mail cadastrado.',
  customer_not_found: 'Cliente não encontrado.',
  coupon_not_found: 'Cupom não encontrado.',
}

/** Manda um e-mail promocional com um cupom existente pro cliente (gerente only). */
export async function sendPromo(
  hotelId: string,
  documentNumber: string,
  token: string,
  couponId: string,
  message?: string,
): Promise<void> {
  let response: Response
  try {
    response = await fetch(
      `${API_BASE_URL}/api/hotels/${hotelId}/customers/${documentNumber}/send-promo`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ couponId, ...(message ? { message } : {}) }),
      },
    )
  } catch {
    throw new ApiError('Não foi possível conectar ao servidor. Tente novamente.', 0)
  }

  if (response.status === 200) return

  let errorCode = 'unknown'
  try {
    const body = (await response.json()) as { error?: string }
    errorCode = body.error ?? 'unknown'
  } catch {
    // corpo não é JSON — segue com a mensagem genérica abaixo.
  }
  throw new ApiError(
    SEND_PROMO_ERROR_MESSAGES[errorCode] ?? `Falha ao enviar e-mail (status ${response.status}).`,
    response.status,
  )
}
