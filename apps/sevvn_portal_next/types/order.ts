/** Portado de apps/konekto_portal/lib/models/order.dart. */
export type OrderStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled'

/**
 * O rótulo muda conforme o tipo de pedido: item físico (Serviço de Quarto)
 * segue um fluxo de preparo/entrega, enquanto reserva agendada (atividade,
 * spa, mesa de restaurante) não "anda" fisicamente — só é confirmada e
 * depois concluída após o horário marcado.
 */
export function orderStatusLabel(status: OrderStatus, isBooking: boolean): string {
  switch (status) {
    case 'pending':
      return isBooking ? 'Aguardando confirmação' : 'Pendente'
    case 'in_progress':
      return isBooking ? 'Confirmado' : 'Preparando'
    case 'completed':
      return 'Concluído'
    case 'cancelled':
      return 'Cancelado'
  }
}

export interface Order {
  id: string
  itemName: string
  quantity: number
  price: number | null
  status: OrderStatus
  note: string | null
  scheduledFor: string | null
  guestName: string
  guestRoomNumber: string
  createdAt: string
  discountAmount: number | null
  couponTitle: string | null
  recordedByStaffId: string | null
  partnerName: string | null
  isPartnerPaid: boolean
}

export function isOrderBooking(order: Pick<Order, 'scheduledFor'>): boolean {
  return order.scheduledFor != null
}

export function isOrderStaffRecorded(order: Pick<Order, 'recordedByStaffId'>): boolean {
  return order.recordedByStaffId != null
}
