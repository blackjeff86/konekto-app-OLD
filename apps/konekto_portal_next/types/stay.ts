/** Portado de apps/konekto_portal/lib/models/stay.dart. */
import type { OrderStatus } from './order'

export type StayStatus = 'active' | 'closed'

export const stayStatusLabel: Record<StayStatus, string> = {
  active: 'Ativa',
  closed: 'Fechada',
}

/** Resumo do quarto/estadia embutido dentro de um Guest. */
export interface StaySummary {
  roomNumber: string
  checkInDate: string
  checkOutDate: string
  status: StayStatus
}

/**
 * Pedido/reserva de um hóspede, aninhado dentro de Guest.orders (página de
 * detalhe) ou StayGuestSummary.orders (resumo de consumo).
 */
export interface GuestOrderSummary {
  id: string
  itemName: string
  quantity: number
  price: number | null
  status: OrderStatus
  note: string | null
  scheduledFor: string | null
  createdAt: string
  discountAmount: number | null
  couponTitle: string | null
  recordedByStaffId: string | null
  partnerName: string | null
  isPartnerPaid: boolean
}

export function isGuestOrderBooking(order: Pick<GuestOrderSummary, 'scheduledFor'>): boolean {
  return order.scheduledFor != null
}

export function isGuestOrderStaffRecorded(
  order: Pick<GuestOrderSummary, 'recordedByStaffId'>,
): boolean {
  return order.recordedByStaffId != null
}

/** Um hóspede dentro de uma estadia, na visão da tela "Quartos". */
export interface StayGuestSummary {
  id: string
  firstName: string
  lastName: string
  accessCode: string
  status: string
  orders: GuestOrderSummary[]
}

export interface StayNotice {
  id: string
  message: string
  createdAt: string
}

export type MessageSender = 'guest' | 'staff'

export interface StayMessage {
  id: string
  senderType: MessageSender
  guestFirstName: string | null
  body: string
  createdAt: string
}

export interface Stay {
  id: string
  roomNumber: string
  checkInDate: string
  checkOutDate: string
  status: StayStatus
  createdAt: string
  guests: StayGuestSummary[]
  notices: StayNotice[]
  messages: StayMessage[]
}

/** Dados do formulário de criação de uma nova estadia. */
export interface NewStayInput {
  roomId: string
  checkInDate: string
  checkOutDate: string
}
