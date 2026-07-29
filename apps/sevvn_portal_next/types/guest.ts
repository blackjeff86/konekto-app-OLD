/** Portado de apps/konekto_portal/lib/models/guest.dart. */
import type { StaySummary, GuestOrderSummary } from './stay'

export type GuestStatus = 'active' | 'revoked'

export type DocumentType = 'cpf' | 'passport' | 'other'

export const documentTypeLabel: Record<DocumentType, string> = {
  cpf: 'CPF',
  passport: 'Passaporte',
  other: 'Outro',
}

/**
 * Hóspede individual de um hotel — sempre vinculado a uma Stay (o
 * quarto/estadia compartilhado com o resto da família). `orders` só vem
 * preenchido no endpoint de DETALHE; na listagem vem vazio.
 */
export interface Guest {
  id: string
  stayId: string
  firstName: string
  lastName: string
  documentType: DocumentType
  documentNumber: string
  phoneCountryCode: string
  phoneNumber: string
  whatsappCountryCode: string | null
  whatsappNumber: string | null
  email: string | null
  address: string | null
  country: string
  wifiPassword: string | null
  accessCode: string
  status: GuestStatus
  createdAt: string
  stay: StaySummary
  orders: GuestOrderSummary[]
}

export function guestFullName(guest: Pick<Guest, 'firstName' | 'lastName'>): string {
  return `${guest.firstName} ${guest.lastName}`
}

/** Dados do formulário de cadastro — sem id/accessCode/status. */
export interface NewGuestInput {
  stayId: string
  firstName: string
  lastName: string
  documentType: DocumentType
  documentNumber: string
  phoneCountryCode: string
  phoneNumber: string
  whatsappCountryCode?: string | null
  whatsappNumber?: string | null
  email?: string | null
  address?: string | null
  country: string
  wifiPassword?: string | null
}

/**
 * Cadastro mais recente de uma pessoa encontrado pelo documento — usado
 * pra reaproveitar dados de alguém que já se hospedou antes.
 */
export interface GuestLookupResult {
  firstName: string
  lastName: string
  documentType: DocumentType
  documentNumber: string
  phoneCountryCode: string
  phoneNumber: string
  whatsappCountryCode: string | null
  whatsappNumber: string | null
  email: string | null
  address: string | null
  country: string
}

/**
 * Dados do formulário de EDIÇÃO — diferente de NewGuestInput, manda os
 * campos opcionais mesmo quando null/undefined, pra permitir LIMPAR um
 * campo (ex: apagar o e-mail).
 */
export interface GuestEditInput {
  firstName: string
  lastName: string
  documentType: DocumentType
  documentNumber: string
  phoneCountryCode: string
  phoneNumber: string
  whatsappCountryCode: string | null
  whatsappNumber: string | null
  email: string | null
  address: string | null
  country: string
  wifiPassword: string | null
}
