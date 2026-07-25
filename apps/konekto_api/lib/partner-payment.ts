interface PartnerPaymentFields {
  partnerId?: string | null
  paymentMode?: 'hotel' | 'partner'
}

type PartnerPaymentValidationResult = { ok: true } | { ok: false; error: string }

// `paymentMode: 'partner'` (hóspede paga o parceiro direto, sem cobrança
// pelo Konekto) só faz sentido com um parceiro selecionado — sem isso o
// item ficaria marcado "pago pelo parceiro" sem ninguém pra pagar.
export function validatePartnerPaymentMode(fields: PartnerPaymentFields): PartnerPaymentValidationResult {
  if (fields.paymentMode === 'partner' && !fields.partnerId) {
    return { ok: false, error: 'payment_mode_requires_partner' }
  }
  return { ok: true }
}
