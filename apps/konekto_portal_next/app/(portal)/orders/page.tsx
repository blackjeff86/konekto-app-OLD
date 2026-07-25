'use client'

import { useOrders } from '@/hooks/useOrders'
import { orderStatusLabel, type Order, type OrderStatus } from '@/types/order'

function formatScheduledFor(iso: string): string {
  const date = new Date(iso)
  const day = date.getUTCDate().toString().padStart(2, '0')
  const month = (date.getUTCMonth() + 1).toString().padStart(2, '0')
  const hour = date.getUTCHours().toString().padStart(2, '0')
  const minute = date.getUTCMinutes().toString().padStart(2, '0')
  return `${day}/${month} às ${hour}:${minute}`
}

const STATUS_COLOR: Record<OrderStatus, string> = {
  pending: 'text-gold',
  in_progress: 'text-[#5B9BD5]',
  completed: 'text-[#5CB85C]',
  cancelled: 'text-slate-soft',
}

function nextStatusOptions(status: OrderStatus): OrderStatus[] {
  switch (status) {
    case 'pending':
      return ['in_progress', 'cancelled']
    case 'in_progress':
      return ['completed', 'cancelled']
    case 'completed':
    case 'cancelled':
      return []
  }
}

/**
 * Tela "Pedidos" — portado de apps/konekto_portal/lib/features/orders/
 * orders_page.dart. Atualiza automaticamente a cada 5s (ver
 * hooks/useOrderNotifications.ts, montado no layout sempre-ativo).
 */
export default function OrdersPage() {
  const { orders, isLoading, error, updateStatus } = useOrders()

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = error instanceof Error ? error.message : null

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-lg font-bold text-cream">Pedidos</h1>
      <p className="text-[12.5px] text-slate">
        Atualiza automaticamente a cada 5 segundos — você recebe um alerta sonoro quando chegar um
        pedido novo, mesmo em outra aba do portal.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {orders.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
          Nenhum pedido ainda.
        </div>
      ) : (
        <div className="divide-y divide-border-strong rounded-2xl border border-border-strong bg-surface">
          {orders.map((order) => (
            <OrderRow
              key={order.id}
              order={order}
              onStatusChange={(status) => updateStatus({ orderId: order.id, status })}
            />
          ))}
        </div>
      )}
    </div>
  )
}

function OrderRow({
  order,
  onStatusChange,
}: {
  order: Order
  onStatusChange: (status: OrderStatus) => void
}) {
  const isBooking = order.scheduledFor != null
  const options = nextStatusOptions(order.status)

  return (
    <div className="flex items-start gap-3 px-5 py-3.5">
      <div className="min-w-0 flex-1">
        <p className="text-sm font-bold text-cream">
          {order.itemName}
          {order.quantity > 1 ? ` ×${order.quantity}` : ''}
        </p>
        <p className="text-xs text-slate">
          {order.guestName} · Quarto {order.guestRoomNumber}
          {order.price != null ? ` · R$ ${(order.price * order.quantity).toFixed(2)}` : ' · Sob consulta'}
        </p>
        {order.scheduledFor && (
          <p className="text-xs font-semibold text-gold">
            Agendado: {formatScheduledFor(order.scheduledFor)}
          </p>
        )}
        {order.note && <p className="text-xs italic text-gold">Obs: {order.note}</p>}
        {order.couponTitle && (
          <p className="text-[11.5px] font-semibold text-gold-light">
            🏷 {order.couponTitle} (-R$ {(order.discountAmount ?? 0).toFixed(2)})
          </p>
        )}
        {order.recordedByStaffId != null && (
          <p className="text-[11px] italic text-slate-soft">Lançado pela recepção</p>
        )}
        {order.isPartnerPaid && (
          <p className="text-[11px] italic text-slate-soft">
            Pago diretamente ao parceiro{order.partnerName ? ` (${order.partnerName})` : ''}
          </p>
        )}
      </div>
      <span
        className={`shrink-0 rounded-full bg-black/10 px-2.5 py-1 text-[11px] font-semibold ${STATUS_COLOR[order.status]}`}
      >
        {orderStatusLabel(order.status, isBooking)}
      </span>
      {options.length > 0 && (
        <select
          aria-label={`Mudar status de ${order.itemName}`}
          value=""
          onChange={(event) => {
            if (event.target.value) onStatusChange(event.target.value as OrderStatus)
          }}
          className="shrink-0 rounded-[8px] border border-border-strong bg-surface px-2 py-1 text-xs text-cream"
        >
          <option value="" disabled>
            •••
          </option>
          {options.map((option) => (
            <option key={option} value={option}>
              {orderStatusLabel(option, isBooking)}
            </option>
          ))}
        </select>
      )}
    </div>
  )
}
