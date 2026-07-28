import { Resend } from 'resend'

export function getResendClient(): Resend {
  const apiKey = process.env.RESEND_API_KEY
  if (!apiKey) {
    throw new Error('Missing required env var: RESEND_API_KEY')
  }
  return new Resend(apiKey)
}

// Endereço "from" — Resend só permite um domínio próprio verificado ou o
// domínio de sandbox deles (`onboarding@resend.dev`, que só entrega pro
// e-mail dono da conta até verificar um domínio real).
export const resendFromAddress = process.env.RESEND_FROM_ADDRESS ?? 'Sevvn <onboarding@resend.dev>'
