/** Portado de apps/konekto_portal/lib/models/customer.dart. */
import type { DocumentType } from './guest'

/**
 * Uma estadia passada ou atual dentro do histórico de um cliente — já vem
 * achatada com o valor gasto naquela estadia especificamente.
 */
export interface CustomerStayEntry {
  stayId: string
  roomNumber: string
  checkInDate: string
  checkOutDate: string
  status: string
  nights: number
  spent: number
}

/**
 * Uma pessoa que já se hospedou no hotel, agregando todas as vezes que ela
 * apareceu (mesmo documentNumber) — não existe tabela própria de "cliente",
 * é montado pela API a partir dos Guest de cada estadia.
 */
export interface Customer {
  documentType: DocumentType
  documentNumber: string
  firstName: string
  lastName: string
  email: string | null
  phoneCountryCode: string
  phoneNumber: string
  whatsappCountryCode: string | null
  whatsappNumber: string | null
  country: string
  visitsCount: number
  totalSpent: number
  firstVisit: string
  lastVisit: string
  stays: CustomerStayEntry[]
}

export function customerFullName(customer: Pick<Customer, 'firstName' | 'lastName'>): string {
  return `${customer.firstName} ${customer.lastName}`
}
