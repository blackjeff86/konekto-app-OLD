'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Modal } from '@/components/ui/Modal'
import { AddGuestDialog } from '@/components/rooms/AddGuestDialog'
import { RoomPickerDialog } from '@/components/rooms/RoomPickerDialog'
import { LaunchConsumptionDialog } from '@/components/rooms/LaunchConsumptionDialog'
import { SimpleAccessCodeDialog } from '@/components/ui/SimpleAccessCodeDialog'
import { useGuests } from '@/hooks/useGuests'
import { useMinibarItems } from '@/hooks/useMinibarItems'
import { useRooms } from '@/hooks/useRooms'
import { useStay } from '@/hooks/useStay'
import { isRoomOccupied } from '@/types/room'
import { stayStatusLabel } from '@/types/stay'
import type { GuestOrderSummary, Stay, StayMessage, StayNotice } from '@/types/stay'
import { orderStatusLabel, type Order } from '@/types/order'
import { formatDate, formatDateTime } from '@/lib/utils/date'

/** Mesma regra de computeStayBill no backend: exclui cancelados e pagos ao parceiro. */
function consumptionTotal(stay: Stay): number {
  let total = 0
  for (const guest of stay.guests) {
    for (const order of guest.orders) {
      if (order.status === 'cancelled') continue
      if (order.isPartnerPaid) continue
      if (order.price != null) total += order.price * order.quantity
    }
  }
  return total
}

type ChatEntry =
  | { kind: 'notice'; notice: StayNotice }
  | { kind: 'message'; message: StayMessage }

function mergedChatEntries(stay: Stay): ChatEntry[] {
  const entries: ChatEntry[] = [
    ...stay.notices.map((notice): ChatEntry => ({ kind: 'notice', notice })),
    ...stay.messages.map((message): ChatEntry => ({ kind: 'message', message })),
  ]
  return entries.sort((a, b) => {
    const aDate = a.kind === 'notice' ? a.notice.createdAt : a.message.createdAt
    const bDate = b.kind === 'notice' ? b.notice.createdAt : b.message.createdAt
    return new Date(bDate).getTime() - new Date(aDate).getTime()
  })
}

interface StayOrderEntry {
  guestName: string
  order: GuestOrderSummary
}

function allOrders(stay: Stay): StayOrderEntry[] {
  const entries: StayOrderEntry[] = stay.guests.flatMap((guest) =>
    guest.orders.map((order) => ({ guestName: `${guest.firstName} ${guest.lastName}`, order })),
  )
  return entries.sort((a, b) => new Date(b.order.createdAt).getTime() - new Date(a.order.createdAt).getTime())
}

/** Portado de StayDetailPage (apps/konekto_portal/lib/features/rooms/stay_detail_page.dart). */
export function StayDetail({ stayId }: { stayId: string }) {
  const {
    stay,
    isLoading,
    error,
    extendStay,
    changeRoom,
    closeStay,
    sendMessage,
    recordConsumption,
  } = useStay(stayId)
  const { rooms } = useRooms()
  const { createGuest } = useGuests()
  const { minibarItems } = useMinibarItems()

  const [noticeText, setNoticeText] = useState('')
  const [isSendingNotice, setIsSendingNotice] = useState(false)
  const [isAddingGuest, setIsAddingGuest] = useState(false)
  const [isChangingRoom, setIsChangingRoom] = useState(false)
  const [isExtending, setIsExtending] = useState(false)
  const [newCheckOutDate, setNewCheckOutDate] = useState('')
  const [isConfirmingClose, setIsConfirmingClose] = useState(false)
  const [isLaunchingConsumption, setIsLaunchingConsumption] = useState(false)
  const [createdAccessCode, setCreatedAccessCode] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  if (!stay) {
    return <p className="text-[13.5px] text-cream">{error instanceof Error ? error.message : 'Não encontrado.'}</p>
  }

  const isActive = stay.status === 'active'
  const total = consumptionTotal(stay)
  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)
  const freeRooms = rooms.filter((room) => !isRoomOccupied(room) && room.number !== stay.roomNumber)

  async function runAction(action: () => Promise<void>) {
    setActionError(null)
    try {
      await action()
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao executar ação.')
    }
  }

  async function handleAddGuest(input: Parameters<typeof createGuest>[0]) {
    const guest = await createGuest(input)
    setIsAddingGuest(false)
    setCreatedAccessCode(guest.accessCode)
  }

  async function handleSendMessage() {
    const message = noticeText.trim()
    if (!message) return
    setIsSendingNotice(true)
    setActionError(null)
    try {
      await sendMessage(message)
      setNoticeText('')
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao enviar a mensagem.')
    } finally {
      setIsSendingNotice(false)
    }
  }

  async function handleConfirmExtend() {
    if (!newCheckOutDate) return
    await runAction(() => extendStay(newCheckOutDate))
    setIsExtending(false)
  }

  async function handleConfirmClose() {
    await runAction(() => closeStay())
    setIsConfirmingClose(false)
  }

  return (
    <div className="flex flex-col gap-4">
      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <div className="whisper-shadow rounded-xl border border-border bg-surface p-6">
        <div className="flex items-center justify-between">
          <p className="text-[13.5px] text-cream">
            {formatDate(stay.checkInDate)} até {formatDate(stay.checkOutDate)}
          </p>
          <span
            className={`rounded-full px-3 py-1 text-[10px] font-bold tracking-wide uppercase ${
              isActive ? 'bg-gold/10 text-gold-light' : 'bg-black/5 text-slate-soft'
            }`}
          >
            {stayStatusLabel[stay.status]}
          </span>
        </div>
        <div className="mt-4 flex items-center gap-2">
          <span className="text-[10.5px] font-bold tracking-wide text-slate uppercase">Valor em aberto:</span>
          <span className="text-lg font-extrabold text-gold-light">R$ {total.toFixed(2)}</span>
        </div>

        {isActive && (
          <>
            <div className="mt-4 flex gap-2.5">
              <button
                type="button"
                onClick={() => {
                  setNewCheckOutDate(stay.checkOutDate.slice(0, 10))
                  setIsExtending(true)
                }}
                className="flex-1 rounded-full border border-border-strong py-2.5 text-[12.5px] font-semibold text-gold-light transition-colors hover:bg-gold/5"
              >
                Estender estadia
              </button>
              <button
                type="button"
                onClick={() => setIsChangingRoom(true)}
                className="flex-1 rounded-full border border-border-strong py-2.5 text-[12.5px] font-semibold text-gold-light transition-colors hover:bg-gold/5"
              >
                Trocar quarto
              </button>
            </div>
            <button
              type="button"
              onClick={() => setIsConfirmingClose(true)}
              className="mt-2.5 w-full rounded-full border border-[#DC262680] py-2.5 text-[12.5px] font-semibold text-[#B3261E] transition-colors hover:bg-[#DC26260D]"
            >
              Fechar conta
            </button>
          </>
        )}
      </div>

      <div className="flex items-center justify-between">
        <h2 className="text-[11px] font-bold tracking-[0.14em] text-slate uppercase">Hóspedes</h2>
        {isActive && (
          <button
            type="button"
            onClick={() => setIsAddingGuest(true)}
            className="text-[12.5px] font-semibold text-gold-light"
          >
            + Adicionar
          </button>
        )}
      </div>
      <div className="whisper-shadow hairline-divide overflow-hidden rounded-xl border border-border bg-surface">
        {stay.guests.length === 0 ? (
          <p className="p-5 text-[13.5px] text-cream">Nenhum hóspede neste quarto ainda.</p>
        ) : (
          stay.guests.map((guest) => {
            const guestIsActive = guest.status === 'active'
            return (
              <Link
                key={guest.id}
                href={`/guests/${guest.id}`}
                className="flex items-center gap-3.5 px-6 py-4 transition-colors hover:bg-surface-alt"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold text-cream">
                    {guest.firstName} {guest.lastName}
                  </p>
                  <p className="truncate text-xs text-slate">{guest.accessCode}</p>
                </div>
                <span
                  className={`shrink-0 rounded-full px-3 py-1 text-[10px] font-bold tracking-wide uppercase ${
                    guestIsActive ? 'bg-gold/10 text-gold-light' : 'bg-black/5 text-slate-soft'
                  }`}
                >
                  {guestIsActive ? 'Ativo' : 'Revogado'}
                </span>
                <span className="shrink-0 text-slate-soft">›</span>
              </Link>
            )
          })
        )}
      </div>

      <div>
        <h2 className="text-[11px] font-bold tracking-[0.14em] text-slate uppercase">Chat com o hóspede</h2>
        <p className="mt-1.5 text-[12.5px] text-slate">
          Visível pra todos os hóspedes deste quarto — eles podem responder pelo app.
        </p>
      </div>
      <div className="flex items-start gap-2.5">
        <textarea
          value={noticeText}
          onChange={(event) => setNoticeText(event.target.value)}
          placeholder="Ex: seu jantar está pronto, checkout às 12h..."
          rows={2}
          className="flex-1 rounded-xl border border-border-strong bg-transparent px-3.5 py-3 text-[13.5px] text-cream outline-none focus:border-gold"
        />
        <button
          type="button"
          aria-label="Enviar mensagem"
          onClick={handleSendMessage}
          disabled={isSendingNotice}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-ink text-white transition-opacity hover:opacity-90 disabled:opacity-60"
        >
          ➤
        </button>
      </div>
      {(stay.notices.length > 0 || stay.messages.length > 0) && (
        <div className="flex flex-col gap-2">
          {mergedChatEntries(stay).map((entry) => (
            <ChatEntryLine key={entry.kind === 'notice' ? entry.notice.id : entry.message.id} entry={entry} />
          ))}
        </div>
      )}

      <div className="flex items-center justify-between">
        <h2 className="text-[11px] font-bold tracking-[0.14em] text-slate uppercase">Pedidos</h2>
        {isActive && (
          <button
            type="button"
            onClick={() => setIsLaunchingConsumption(true)}
            className="text-[12.5px] font-semibold text-gold-light"
          >
            🧊 Lançar consumo
          </button>
        )}
      </div>
      <p className="text-[12.5px] text-slate">
        Todos os pedidos e reservas feitos pelos hóspedes deste quarto — é o que forma o valor em
        aberto acima.
      </p>
      <div className="whisper-shadow hairline-divide overflow-hidden rounded-xl border border-border bg-surface">
        {allOrders(stay).length === 0 ? (
          <p className="p-5 text-[13.5px] text-cream">Nenhum pedido registrado ainda.</p>
        ) : (
          allOrders(stay).map((entry) => (
            <StayOrderRow
              key={entry.order.id}
              entry={entry}
              showGuestName={stay.guests.length > 1}
            />
          ))
        )}
      </div>

      {isAddingGuest && (
        <AddGuestDialog
          stayId={stayId}
          onClose={() => setIsAddingGuest(false)}
          onSubmit={handleAddGuest}
        />
      )}

      {createdAccessCode && (
        <SimpleAccessCodeDialog accessCode={createdAccessCode} onClose={() => setCreatedAccessCode(null)} />
      )}

      {isChangingRoom && (
        <RoomPickerDialog
          rooms={freeRooms}
          onClose={() => setIsChangingRoom(false)}
          onSubmit={async (roomId) => {
            await runAction(() => changeRoom(roomId))
            setIsChangingRoom(false)
          }}
        />
      )}

      {isLaunchingConsumption && (
        <LaunchConsumptionDialog
          guests={stay.guests}
          minibarItems={minibarItems}
          onClose={() => setIsLaunchingConsumption(false)}
          onSubmit={async (input) => {
            await runAction(() => recordConsumption(input))
            setIsLaunchingConsumption(false)
          }}
        />
      )}

      {isExtending && (
        <Modal
          title="Estender estadia"
          onClose={() => setIsExtending(false)}
          footer={
            <>
              <button type="button" onClick={() => setIsExtending(false)} className="text-sm text-slate">
                Cancelar
              </button>
              <button
                type="button"
                onClick={handleConfirmExtend}
                className="text-sm font-semibold text-gold-light"
              >
                Confirmar
              </button>
            </>
          }
        >
          <label className="text-xs text-slate">
            Nova data de saída
            <input
              type="date"
              value={newCheckOutDate}
              onChange={(event) => setNewCheckOutDate(event.target.value)}
              className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
            />
          </label>
        </Modal>
      )}

      {isConfirmingClose && (
        <Modal
          title={`Fechar conta do quarto ${stay.roomNumber}?`}
          onClose={() => setIsConfirmingClose(false)}
          footer={
            <>
              <button
                type="button"
                onClick={() => setIsConfirmingClose(false)}
                className="text-sm text-slate"
              >
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmClose} className="text-sm text-[#B3261E]">
                Fechar conta
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            Isso revoga o código de acesso de todos os {stay.guests.length} hóspede
            {stay.guests.length === 1 ? '' : 's'} deste quarto — ninguém mais consegue entrar no
            app.
          </p>
          <p className="mt-3 text-xs text-slate">Total consumido:</p>
          <p className="text-xl font-bold text-gold-light">R$ {total.toFixed(2)}</p>
        </Modal>
      )}
    </div>
  )
}

function ChatEntryLine({ entry }: { entry: ChatEntry }) {
  const label =
    entry.kind === 'notice'
      ? 'Aviso (histórico)'
      : entry.message.senderType === 'staff'
        ? 'Recepção'
        : (entry.message.guestFirstName ?? 'Hóspede')
  const body = entry.kind === 'notice' ? entry.notice.message : entry.message.body
  const createdAt = entry.kind === 'notice' ? entry.notice.createdAt : entry.message.createdAt
  const isStaff = entry.kind === 'message' && entry.message.senderType === 'staff'

  return (
    <div className="rounded-xl border border-border bg-surface-alt/60 px-4 py-3">
      <p className={`text-[10.5px] font-bold tracking-wide uppercase ${isStaff ? 'text-gold-light' : 'text-slate'}`}>{label}</p>
      <p className="mt-1 text-[13px] text-cream">{body}</p>
      <p className="mt-1 text-[11px] text-slate-soft">{formatDateTime(createdAt)}</p>
    </div>
  )
}

const ORDER_STATUS_COLOR: Record<Order['status'], string> = {
  pending: 'text-gold-light',
  in_progress: 'text-gold-light',
  completed: 'text-slate-soft',
  cancelled: 'text-[#B3261E]',
}

function StayOrderRow({
  entry,
  showGuestName,
}: {
  entry: StayOrderEntry
  showGuestName: boolean
}) {
  const { order, guestName } = entry
  const isBooking = order.scheduledFor != null

  return (
    <div className="flex items-start gap-3 px-6 py-4">
      <div className="min-w-0 flex-1">
        <p className="text-sm font-bold text-cream">
          {order.quantity}x {order.itemName}
        </p>
        <p className="text-xs text-slate">
          {showGuestName ? `${guestName} · ${formatDateTime(order.createdAt)}` : formatDateTime(order.createdAt)}
        </p>
        {order.note && <p className="text-xs text-slate-soft">{order.note}</p>}
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
            Pago diretamente ao parceiro{order.partnerName ? ` (${order.partnerName})` : ''} — não
            entra na conta do quarto
          </p>
        )}
      </div>
      <div className="shrink-0 text-right">
        <p className="text-sm font-bold text-gold-light">
          {order.price != null ? `R$ ${(order.price * order.quantity).toFixed(2)}` : '—'}
        </p>
        <span
          className={`mt-1 inline-block rounded-full bg-black/10 px-2.5 py-1 text-[11px] font-semibold ${ORDER_STATUS_COLOR[order.status]}`}
        >
          {orderStatusLabel(order.status, isBooking)}
        </span>
      </div>
    </div>
  )
}
