/** Portado de apps/konekto_portal/lib/data/payment_repository.dart. */
import { apiRequest, ApiError } from './client'
import { paymentAccountStatusFromRaw, type PaymentAccount } from '@/types/payment'

interface RawPaymentAccount {
  configured?: boolean
  status?: string | null
  recipientId?: string | null
  pagarmeStatus?: string | null
}

function mapAccount(raw: RawPaymentAccount): PaymentAccount {
  return {
    status: paymentAccountStatusFromRaw(raw),
    recipientId: raw.recipientId ?? null,
    pagarmeStatus: raw.pagarmeStatus ?? null,
  }
}

export function getPaymentAccount(hotelId: string, token: string): Promise<PaymentAccount> {
  return apiRequest<RawPaymentAccount>(`/api/hotels/${hotelId}/payment-recipient`, {
    token,
    errorMessage: 'Falha ao carregar dados de pagamento.',
  }).then(mapAccount)
}

export async function setPaymentRecipientId(
  hotelId: string,
  token: string,
  recipientId: string,
): Promise<PaymentAccount> {
  try {
    const raw = await apiRequest<RawPaymentAccount>(`/api/hotels/${hotelId}/payment-recipient`, {
      method: 'POST',
      token,
      body: { recipientId },
      errorMessage: 'Falha ao salvar dados de pagamento.',
    })
    return mapAccount(raw)
  } catch (error) {
    if (error instanceof ApiError && error.status === 400) {
      throw new ApiError(
        'Não encontramos esse Recipient ID no Pagar.me — confira se foi colado corretamente.',
        400,
      )
    }
    throw error
  }
}
