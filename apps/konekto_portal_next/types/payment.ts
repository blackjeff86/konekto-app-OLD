/** Portado de apps/konekto_portal/lib/data/payment_repository.dart. */
export type PaymentAccountStatus = 'not_configured' | 'pending' | 'verified' | 'rejected'

export interface PaymentAccount {
  status: PaymentAccountStatus
  recipientId: string | null
  pagarmeStatus: string | null
}

export function paymentAccountStatusFromRaw(raw: {
  configured?: boolean
  status?: string | null
}): PaymentAccountStatus {
  if (raw.configured !== true) return 'not_configured'
  if (raw.status === 'verified') return 'verified'
  if (raw.status === 'rejected') return 'rejected'
  return 'pending'
}
