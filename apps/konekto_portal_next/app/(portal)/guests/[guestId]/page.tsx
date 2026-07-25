'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { Modal } from '@/components/ui/Modal'
import { CopyableCodeBox } from '@/components/ui/CopyableCodeBox'
import { GuestEditDialog } from '@/components/guests/GuestEditDialog'
import { useGuest } from '@/hooks/useGuests'
import { documentTypeLabel, guestFullName, type Guest } from '@/types/guest'
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

  const initials = guestInitials(guest)

  return (
    <div className="flex flex-col gap-10">
      <Link
        href="/guests"
        aria-label="Voltar"
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border text-slate transition-colors hover:bg-surface-alt"
      >
        ←
      </Link>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {/* Cabeçalho: avatar com iniciais (sem foto real — hóspedes não têm foto cadastrada) + nome + status. */}
      <div className="flex items-center gap-6">
        <div className="flex h-24 w-24 shrink-0 items-center justify-center rounded-2xl bg-gold/12 text-2xl font-extrabold text-gold-light">
          {initials}
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <h1 className="text-4xl font-extrabold tracking-tight text-cream">{guestFullName(guest)}</h1>
          <span
            className={`rounded-full border px-3 py-1 text-[10px] font-bold tracking-wide uppercase ${
              isActive ? 'border-gold/20 bg-gold/10 text-gold-light' : 'border-border-strong bg-black/5 text-slate-soft'
            }`}
          >
            {isActive ? 'Ativo' : 'Revogado'}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-8 items-start">
        <SectionCard
          className="col-span-12 lg:col-span-7"
          title="Cadastro"
          trailing={
            <button
              type="button"
              aria-label="Editar cadastro"
              onClick={() => setIsEditing(true)}
              className="text-slate transition-colors hover:text-gold-light"
            >
              ✎
            </button>
          }
        >
          <div className="grid grid-cols-1 gap-y-5 sm:grid-cols-2 sm:gap-x-6">
            <DetailBlock label="Documento" value={`${documentTypeLabel[guest.documentType]} · ${guest.documentNumber}`} />
            <DetailBlock label="País" value={guest.country} />
            <DetailBlock label="Telefone" value={`${guest.phoneCountryCode} ${guest.phoneNumber}`} />
            {guest.whatsappNumber && (
              <DetailBlock label="WhatsApp" value={`${guest.whatsappCountryCode} ${guest.whatsappNumber}`} accent />
            )}
            {guest.email && <DetailBlock label="E-mail" value={guest.email} />}
            {guest.address && <DetailBlock label="Endereço" value={guest.address} />}
          </div>

          <div className="mt-8 flex flex-col gap-4 border-t border-border pt-8">
            <div>
              <p className="mb-2 text-[10px] font-bold tracking-wide text-slate uppercase">Senha de wifi</p>
              <div className="flex items-center justify-between rounded-xl border border-border bg-surface-alt/60 px-4 py-3">
                <span className="text-[13px] italic text-cream">{guest.wifiPassword ?? 'Padrão do hotel'}</span>
                <span aria-hidden className="text-slate">📶</span>
              </div>
            </div>
            <div>
              <p className="mb-2 text-[10px] font-bold tracking-wide text-slate uppercase">Código de acesso</p>
              <CopyableCodeBox value={guest.accessCode} fontSize={16} />
            </div>
          </div>
        </SectionCard>

        <div className="col-span-12 flex flex-col gap-8 lg:col-span-5">
          <SectionCard title="Quarto" accentBorder>
            <div className="mb-5 flex items-center gap-4">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-gold/12 text-xl">
                🚪
              </div>
              <div>
                <p className="text-[10px] font-bold tracking-wide text-slate uppercase">Número do quarto</p>
                <p className="text-2xl font-extrabold tracking-tight text-cream">{guest.stay.roomNumber}</p>
              </div>
            </div>
            <div className="flex flex-col gap-3 text-[12.5px]">
              <div className="flex items-center justify-between border-b border-border pb-3">
                <span className="text-slate">Estadia</span>
                <span className="font-semibold text-cream">
                  {formatDate(guest.stay.checkInDate)} — {formatDate(guest.stay.checkOutDate)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate">Status</span>
                <span className="font-semibold text-cream">{stayStatusLabel[guest.stay.status]}</span>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Pedidos e reservas">
            {guest.orders.length === 0 ? (
              <p className="text-[13px] text-cream">Nenhum pedido ainda.</p>
            ) : (
              <div className="flex flex-col gap-3">
                {guest.orders.map((order) => (
                  <OrderLine key={order.id} order={order} />
                ))}
              </div>
            )}
          </SectionCard>
        </div>
      </div>

      {isActive && (
        <div className="flex justify-center pb-4">
          <button
            type="button"
            onClick={() => setIsConfirmingRevoke(true)}
            className="rounded-full border-2 border-ink px-10 py-3.5 text-[12px] font-bold tracking-[0.1em] text-ink uppercase transition-colors hover:bg-ink hover:text-white"
          >
            Revogar acesso ao hóspede
          </button>
        </div>
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
  className = '',
  accentBorder = false,
}: {
  title: string
  trailing?: React.ReactNode
  children: React.ReactNode
  className?: string
  accentBorder?: boolean
}) {
  return (
    <div
      className={`whisper-shadow rounded-2xl border border-border bg-surface p-7 ${accentBorder ? 'border-l-4 border-l-gold' : ''} ${className}`}
    >
      <div className="mb-6 flex items-center justify-between">
        <h2 className="text-[11px] font-bold tracking-[0.2em] text-slate uppercase">{title}</h2>
        {trailing}
      </div>
      {children}
    </div>
  )
}

function DetailBlock({ label, value, accent = false }: { label: string; value: string; accent?: boolean }) {
  return (
    <div>
      <p className="mb-1 text-[10px] font-bold tracking-wide text-slate uppercase">{label}</p>
      <p className={`text-[15px] ${accent ? 'font-semibold text-gold-light' : 'text-cream'}`}>{value}</p>
    </div>
  )
}

function guestInitials(guest: Pick<Guest, 'firstName' | 'lastName'>): string {
  return `${guest.firstName.charAt(0)}${guest.lastName.charAt(0)}`.toUpperCase()
}

function OrderLine({ order }: { order: GuestOrderSummary }) {
  const isBooking = isGuestOrderBooking(order)
  return (
    <div className="flex items-start gap-3 rounded-xl border border-border bg-surface-alt/60 p-4">
      <div className="min-w-0 flex-1">
        <p className="text-[13.5px] font-bold text-cream">
          {order.itemName}
          {order.quantity > 1 ? ` ×${order.quantity}` : ''}
        </p>
        <p className="mt-0.5 text-xs text-slate">
          {order.price != null ? `R$ ${(order.price * order.quantity).toFixed(2)}` : 'Sob consulta'}
        </p>
        {order.scheduledFor && (
          <p className="mt-1 text-xs font-semibold text-gold">
            Agendado: {formatDateTime(order.scheduledFor)}
          </p>
        )}
        {order.note && <p className="mt-1 text-xs italic text-slate">Obs: {order.note}</p>}
        {isGuestOrderStaffRecorded(order) && (
          <p className="mt-1 text-[11px] italic text-slate-soft">Lançado pela recepção</p>
        )}
        {order.isPartnerPaid && (
          <p className="mt-1 text-[11px] italic text-slate-soft">
            Pago diretamente ao parceiro{order.partnerName ? ` (${order.partnerName})` : ''}
          </p>
        )}
      </div>
      <span
        className={`shrink-0 rounded-full bg-black/10 px-2.5 py-1 text-[10px] font-bold tracking-wide uppercase ${STATUS_COLOR[order.status]}`}
      >
        {orderStatusLabel(order.status, isBooking)}
      </span>
    </div>
  )
}
