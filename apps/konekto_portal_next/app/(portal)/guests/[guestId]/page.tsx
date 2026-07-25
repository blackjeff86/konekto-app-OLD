'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { Modal } from '@/components/ui/Modal'
import { CopyableCodeBox } from '@/components/ui/CopyableCodeBox'
import { GuestEditDialog } from '@/components/guests/GuestEditDialog'
import { useGuest } from '@/hooks/useGuests'
import { documentTypeLabel, guestFullName } from '@/types/guest'
import { stayStatusLabel } from '@/types/stay'
import { isGuestOrderBooking, isGuestOrderStaffRecorded, type GuestOrderSummary } from '@/types/stay'
import { orderStatusLabel } from '@/types/order'
import { formatDate } from '@/lib/utils/date'

/** Formato "às HH:MM" específico desta tela (guest_detail_page.dart usa esse separador; stay_detail_page.dart usa só espaço). */
function formatDateTime(iso: string): string {
  const date = new Date(iso)
  const hour = date.getUTCHours().toString().padStart(2, '0')
  const minute = date.getUTCMinutes().toString().padStart(2, '0')
  return `${formatDate(iso)} às ${hour}:${minute}`
}

const STATUS_COLOR: Record<string, string> = {
  pending: 'text-gold',
  in_progress: 'text-[#5B9BD5]',
  completed: 'text-[#5CB85C]',
  cancelled: 'text-slate-soft',
}

/** Portado de apps/konekto_portal/lib/features/guests/guest_detail_page.dart. */
export default function GuestDetailPage({ params }: { params: Promise<{ guestId: string }> }) {
  const { guestId } = use(params)
  const { guest, isLoading, error, updateGuest, revokeGuest } = useGuest(guestId)
  const [isEditing, setIsEditing] = useState(false)
  const [isConfirmingRevoke, setIsConfirmingRevoke] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  if (!guest) {
    const message = error instanceof Error ? error.message : 'Hóspede não encontrado.'
    return <p className="text-[13.5px] text-cream">{message}</p>
  }

  const isActive = guest.status === 'active'
  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)

  async function handleRevoke() {
    setActionError(null)
    try {
      await revokeGuest()
      setIsConfirmingRevoke(false)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao revogar hóspede.')
      setIsConfirmingRevoke(false)
    }
  }

  return (
    <div className="mx-auto flex max-w-[640px] flex-col gap-4">
      <div className="flex items-center gap-2">
        <Link href="/guests" aria-label="Voltar" className="text-slate">
          ←
        </Link>
        <h1 className="flex-1 text-lg font-bold text-cream">{guestFullName(guest)}</h1>
      </div>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <SectionCard
        title="Cadastro"
        trailing={
          <div className="flex items-center gap-2">
            <span
              className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${
                isActive ? 'bg-gold/12 text-gold-light' : 'bg-black/5 text-slate-soft'
              }`}
            >
              {isActive ? 'Ativo' : 'Revogado'}
            </span>
            <button
              type="button"
              aria-label="Editar cadastro"
              onClick={() => setIsEditing(true)}
              className="text-slate"
            >
              ✎
            </button>
          </div>
        }
      >
        <DetailLine label="Documento" value={`${documentTypeLabel[guest.documentType]} · ${guest.documentNumber}`} />
        <DetailLine label="Telefone" value={`${guest.phoneCountryCode} ${guest.phoneNumber}`} />
        {guest.whatsappNumber && (
          <DetailLine label="WhatsApp" value={`${guest.whatsappCountryCode} ${guest.whatsappNumber}`} />
        )}
        {guest.email && <DetailLine label="E-mail" value={guest.email} />}
        {guest.address && <DetailLine label="Endereço" value={guest.address} />}
        <DetailLine label="País" value={guest.country} />
        <DetailLine label="Senha de wifi" value={guest.wifiPassword ?? 'Padrão do hotel'} />
        <div className="flex items-start gap-2 pb-2.5">
          <span className="w-36 shrink-0 text-xs text-slate">Código de acesso</span>
          <div className="flex-1">
            <CopyableCodeBox value={guest.accessCode} fontSize={13} />
          </div>
        </div>
      </SectionCard>

      <SectionCard title="Quarto">
        <DetailLine label="Número" value={guest.stay.roomNumber} />
        <DetailLine
          label="Estadia"
          value={`${formatDate(guest.stay.checkInDate)} até ${formatDate(guest.stay.checkOutDate)}`}
        />
        <DetailLine label="Status da estadia" value={stayStatusLabel[guest.stay.status]} />
      </SectionCard>

      <SectionCard title="Pedidos e reservas">
        {guest.orders.length === 0 ? (
          <p className="text-[13px] text-cream">Nenhum pedido ainda.</p>
        ) : (
          guest.orders.map((order) => <OrderLine key={order.id} order={order} />)
        )}
      </SectionCard>

      {isActive && (
        <button
          type="button"
          onClick={() => setIsConfirmingRevoke(true)}
          className="rounded-[10px] border border-[#DC262680] py-3 text-[13px] text-[#B3261E]"
        >
          Revogar acesso
        </button>
      )}

      {isEditing && (
        <GuestEditDialog
          guest={guest}
          onClose={() => setIsEditing(false)}
          onSubmit={async (input) => {
            await updateGuest(input)
            setIsEditing(false)
          }}
        />
      )}

      {isConfirmingRevoke && (
        <Modal
          title="Revogar acesso?"
          onClose={() => setIsConfirmingRevoke(false)}
          footer={
            <>
              <button
                type="button"
                onClick={() => setIsConfirmingRevoke(false)}
                className="text-sm text-slate"
              >
                Cancelar
              </button>
              <button type="button" onClick={handleRevoke} className="text-sm text-[#B3261E]">
                Revogar
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            &ldquo;{guestFullName(guest)}&rdquo; não vai mais conseguir entrar no app com esse
            código.
          </p>
        </Modal>
      )}
    </div>
  )
}

function SectionCard({
  title,
  trailing,
  children,
}: {
  title: string
  trailing?: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <div className="rounded-2xl border border-border-strong bg-surface p-4.5">
      <div className="mb-3 flex items-center justify-between">
        <h2 className="text-[15px] font-bold text-cream">{title}</h2>
        {trailing}
      </div>
      {children}
    </div>
  )
}

function DetailLine({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start gap-2 pb-2.5">
      <span className="w-36 shrink-0 text-xs text-slate">{label}</span>
      <span className="text-[13px] text-cream">{value}</span>
    </div>
  )
}

function OrderLine({ order }: { order: GuestOrderSummary }) {
  const isBooking = isGuestOrderBooking(order)
  return (
    <div className="flex items-start gap-2 pb-3">
      <div className="flex-1">
        <p className="text-[13.5px] font-bold text-cream">
          {order.itemName}
          {order.quantity > 1 ? ` ×${order.quantity}` : ''}
        </p>
        <p className="text-xs text-slate">
          {order.price != null ? `R$ ${(order.price * order.quantity).toFixed(2)}` : 'Sob consulta'}
        </p>
        {order.scheduledFor && (
          <p className="text-xs font-semibold text-gold">
            Agendado: {formatDateTime(order.scheduledFor)}
          </p>
        )}
        {order.note && <p className="text-xs italic text-slate">Obs: {order.note}</p>}
        {isGuestOrderStaffRecorded(order) && (
          <p className="text-[11px] italic text-slate-soft">Lançado pela recepção</p>
        )}
        {order.isPartnerPaid && (
          <p className="text-[11px] italic text-slate-soft">
            Pago diretamente ao parceiro{order.partnerName ? ` (${order.partnerName})` : ''}
          </p>
        )}
      </div>
      <span className={`shrink-0 rounded-full bg-black/10 px-2.5 py-1 text-[11px] font-semibold ${STATUS_COLOR[order.status]}`}>
        {orderStatusLabel(order.status, isBooking)}
      </span>
    </div>
  )
}
