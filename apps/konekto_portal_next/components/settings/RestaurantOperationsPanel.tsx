'use client'

import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth/AuthProvider'
import { useGuests } from '@/hooks/useGuests'
import {
  createRestaurantWaitlistEntry,
  getRestaurantOperations,
  releaseRestaurantReservation,
  updateRestaurantWaitlistEntry,
} from '@/lib/api/services'
import { guestFullName } from '@/types/guest'
import type { RestaurantReservationOperation, RestaurantWaitlistEntry, RestaurantTableType } from '@/types/service'

function formatUtcDateTime(iso: string): string {
  const value = new Date(iso)
  const day = value.getUTCDate().toString().padStart(2, '0')
  const month = (value.getUTCMonth() + 1).toString().padStart(2, '0')
  const year = value.getUTCFullYear()
  const hours = value.getUTCHours().toString().padStart(2, '0')
  const minutes = value.getUTCMinutes().toString().padStart(2, '0')
  return `${day}/${month}/${year} às ${hours}:${minutes}`
}

function combineLocalDateTime(date: string, time: string): string | null {
  if (!date || !time) return null
  const value = new Date(`${date}T${time}:00`)
  if (Number.isNaN(value.getTime())) return null
  return value.toISOString()
}

function reservationStatusLabel(status: RestaurantReservationOperation['status']) {
  switch (status) {
    case 'pending':
      return 'Aguardando confirmação'
    case 'in_progress':
      return 'Confirmada'
    case 'completed':
      return 'Concluída'
    case 'cancelled':
      return 'Cancelada'
  }
}

function waitlistStatusLabel(status: RestaurantWaitlistEntry['status']) {
  switch (status) {
    case 'waiting':
      return 'Na fila'
    case 'promoted':
      return 'Promovido'
    case 'cancelled':
      return 'Cancelado'
  }
}

export function RestaurantOperationsPanel({
  serviceId,
  tableTypes,
}: {
  serviceId: string
  tableTypes: RestaurantTableType[]
}) {
  const { session, token } = useAuth()
  const hotelId = session?.hotelId
  const queryClient = useQueryClient()
  const queryKey = ['restaurant-operations', hotelId, serviceId] as const
  const { guests } = useGuests()

  const [guestId, setGuestId] = useState('')
  const [partySize, setPartySize] = useState('2')
  const [scheduledDate, setScheduledDate] = useState('')
  const [scheduledTime, setScheduledTime] = useState('')
  const [tableTypeId, setTableTypeId] = useState('')
  const [priority, setPriority] = useState('100')
  const [note, setNote] = useState('')
  const [actionError, setActionError] = useState<string | null>(null)

  const query = useQuery({
    queryKey,
    queryFn: () => getRestaurantOperations(hotelId!, serviceId, token!),
    enabled: Boolean(hotelId && token),
  })

  const invalidate = () => queryClient.invalidateQueries({ queryKey })

  const createMutation = useMutation({
    mutationFn: (input: {
      guestId: string
      partySize: number
      scheduledFor: string
      tableTypeId?: string | null
      priority?: number
      note?: string | null
    }) => createRestaurantWaitlistEntry(hotelId!, serviceId, token!, input),
    onSuccess: () => {
      invalidate()
      setGuestId('')
      setPartySize('2')
      setScheduledDate('')
      setScheduledTime('')
      setTableTypeId('')
      setPriority('100')
      setNote('')
      setActionError(null)
    },
    onError: (error) => setActionError(error instanceof Error ? error.message : 'Falha ao adicionar na fila.'),
  })

  const waitlistMutation = useMutation({
    mutationFn: ({
      entryId,
      input,
    }: {
      entryId: string
      input: { action: 'reprioritize'; priority: number } | { action: 'cancel' } | { action: 'promote' }
    }) => updateRestaurantWaitlistEntry(hotelId!, serviceId, entryId, token!, input),
    onSuccess: () => {
      invalidate()
      setActionError(null)
    },
    onError: (error) => setActionError(error instanceof Error ? error.message : 'Falha ao atualizar a fila.'),
  })

  const releaseMutation = useMutation({
    mutationFn: (orderId: string) => releaseRestaurantReservation(hotelId!, serviceId, token!, { orderId, autoPromoteNext: true }),
    onSuccess: () => {
      invalidate()
      setActionError(null)
    },
    onError: (error) => setActionError(error instanceof Error ? error.message : 'Falha ao liberar a mesa.'),
  })

  const activeGuests = guests.filter((guest) => guest.status === 'active' && guest.stay.status === 'active')
  const operations = query.data

  return (
    <section className="rounded-2xl border border-border-strong bg-surface p-[18px]">
      <div className="flex flex-col gap-1">
        <h2 className="text-sm font-bold text-cream">Operação do restaurante</h2>
        <p className="text-xs text-slate">
          Acompanhe reservas, fila de espera e liberação de mesa da equipe em tempo real.
        </p>
      </div>

      {actionError && (
        <div className="mt-4 rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {actionError}
        </div>
      )}

      {query.isLoading ? (
        <div className="mt-5 flex justify-center py-6">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
        </div>
      ) : operations ? (
        <div className="mt-5 flex flex-col gap-5">
          <div className="grid gap-3 md:grid-cols-3">
            <MetricCard label="Reservas ativas" value={operations.reservations.filter((entry) => entry.status !== 'cancelled').length} />
            <MetricCard label="Fila aguardando" value={operations.waitlist.filter((entry) => entry.status === 'waiting').length} />
            <MetricCard
              label="Expiração"
              value={
                operations.configuration.reservationExpiryMinutes != null
                  ? `${operations.configuration.reservationExpiryMinutes} min`
                  : 'Desligada'
              }
            />
          </div>

          <div className="rounded-xl border border-border-strong px-4 py-4">
            <div className="flex flex-col gap-1">
              <h3 className="text-[13px] font-bold text-cream">Adicionar à fila de espera</h3>
              <p className="text-[11.5px] text-slate">
                A fila usa apenas hóspedes ativos deste hotel para manter a operação segura por hospedagem.
              </p>
            </div>
            {!operations.configuration.waitlistEnabled ? (
              <p className="mt-3 text-xs text-slate">
                A fila de espera está desligada na configuração do módulo restaurante.
              </p>
            ) : (
              <form
                className="mt-4 grid gap-3 md:grid-cols-2"
                onSubmit={(event) => {
                  event.preventDefault()
                  const scheduledFor = combineLocalDateTime(scheduledDate, scheduledTime)
                  if (!guestId || !scheduledFor) {
                    setActionError('Selecione o hóspede e informe dia e horário da fila.')
                    return
                  }
                  createMutation.mutate({
                    guestId,
                    partySize: Number(partySize),
                    scheduledFor,
                    tableTypeId: tableTypeId || null,
                    priority: Number(priority),
                    note: note.trim() ? note.trim() : null,
                  })
                }}
              >
                <label className="flex flex-col gap-1 text-[12px] text-slate">
                  Hóspede
                  <select
                    value={guestId}
                    onChange={(event) => setGuestId(event.target.value)}
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  >
                    <option value="">Selecione um hóspede ativo</option>
                    {activeGuests.map((guest) => (
                      <option key={guest.id} value={guest.id}>
                        {guestFullName(guest)} · Quarto {guest.stay.roomNumber}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="flex flex-col gap-1 text-[12px] text-slate">
                  Mesa para quantos
                  <input
                    value={partySize}
                    onChange={(event) => setPartySize(event.target.value)}
                    type="number"
                    min={1}
                    max={40}
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  />
                </label>

                <label className="flex flex-col gap-1 text-[12px] text-slate">
                  Data
                  <input
                    value={scheduledDate}
                    onChange={(event) => setScheduledDate(event.target.value)}
                    type="date"
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  />
                </label>

                <label className="flex flex-col gap-1 text-[12px] text-slate">
                  Horário
                  <input
                    value={scheduledTime}
                    onChange={(event) => setScheduledTime(event.target.value)}
                    type="time"
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  />
                </label>

                <label className="flex flex-col gap-1 text-[12px] text-slate">
                  Tipo de mesa
                  <select
                    value={tableTypeId}
                    onChange={(event) => setTableTypeId(event.target.value)}
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  >
                    <option value="">Melhor encaixe / sem tipo fixo</option>
                    {tableTypes.map((tableType) => (
                      <option key={tableType.id} value={tableType.id}>
                        {tableType.label ?? `${tableType.seats} lugares`} · {tableType.quantity} mesas
                      </option>
                    ))}
                  </select>
                </label>

                <label className="flex flex-col gap-1 text-[12px] text-slate">
                  Prioridade
                  <input
                    value={priority}
                    onChange={(event) => setPriority(event.target.value)}
                    type="number"
                    min={0}
                    max={999}
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  />
                </label>

                <label className="md:col-span-2 flex flex-col gap-1 text-[12px] text-slate">
                  Observação
                  <textarea
                    value={note}
                    onChange={(event) => setNote(event.target.value)}
                    rows={3}
                    className="rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13px] text-cream"
                  />
                </label>

                <div className="md:col-span-2 flex justify-end">
                  <button
                    type="submit"
                    disabled={createMutation.isPending}
                    className="rounded-full bg-gold px-4 py-2 text-[12.5px] font-semibold text-[#1F1600] disabled:opacity-60"
                  >
                    {createMutation.isPending ? 'Adicionando...' : 'Adicionar à fila'}
                  </button>
                </div>
              </form>
            )}
          </div>

          <div className="grid gap-5 lg:grid-cols-2">
            <div className="rounded-xl border border-border-strong px-4 py-4">
              <div className="flex items-center justify-between">
                <h3 className="text-[13px] font-bold text-cream">Reservas do restaurante</h3>
                <span className="text-[11.5px] text-slate">{operations.reservations.length} registro(s)</span>
              </div>
              <div className="mt-3 flex flex-col gap-3">
                {operations.reservations.length === 0 ? (
                  <p className="text-xs text-slate">Nenhuma reserva registrada para este restaurante.</p>
                ) : (
                  operations.reservations.map((reservation) => (
                    <div key={reservation.id} className="rounded-[12px] border border-border-strong px-3 py-3">
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="text-[13px] font-semibold text-cream">
                            {reservation.guestName} · Quarto {reservation.roomNumber}
                          </p>
                          <p className="mt-1 text-[11.5px] text-slate">{formatUtcDateTime(reservation.scheduledFor)}</p>
                          {reservation.tableTypeLabel && (
                            <p className="mt-1 text-[11.5px] text-slate">Mesa: {reservation.tableTypeLabel}</p>
                          )}
                          {reservation.expiresAt && (
                            <p className="mt-1 text-[11.5px] text-gold-light">
                              Expira em {formatUtcDateTime(reservation.expiresAt)}
                            </p>
                          )}
                          {reservation.note && <p className="mt-1 text-[11.5px] italic text-slate">{reservation.note}</p>}
                        </div>
                        <span className="rounded-full bg-gold/10 px-3 py-1 text-[10px] font-bold tracking-wide text-gold-light uppercase">
                          {reservationStatusLabel(reservation.status)}
                        </span>
                      </div>
                      {reservation.status !== 'cancelled' && reservation.status !== 'completed' && (
                        <div className="mt-3 flex justify-end">
                          <button
                            type="button"
                            onClick={() => releaseMutation.mutate(reservation.id)}
                            disabled={releaseMutation.isPending}
                            className="text-[12px] font-semibold text-gold-light"
                          >
                            Liberar mesa e puxar próximo da fila
                          </button>
                        </div>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>

            <div className="rounded-xl border border-border-strong px-4 py-4">
              <div className="flex items-center justify-between">
                <h3 className="text-[13px] font-bold text-cream">Fila de espera</h3>
                <span className="text-[11.5px] text-slate">{operations.waitlist.length} registro(s)</span>
              </div>
              <div className="mt-3 flex flex-col gap-3">
                {operations.waitlist.length === 0 ? (
                  <p className="text-xs text-slate">Nenhum hóspede na fila de espera.</p>
                ) : (
                  operations.waitlist.map((entry) => (
                    <WaitlistRow
                      key={entry.id}
                      entry={entry}
                      onReprioritize={(nextPriority) =>
                        waitlistMutation.mutate({
                          entryId: entry.id,
                          input: { action: 'reprioritize', priority: nextPriority },
                        })
                      }
                      onPromote={() => waitlistMutation.mutate({ entryId: entry.id, input: { action: 'promote' } })}
                      onCancel={() => waitlistMutation.mutate({ entryId: entry.id, input: { action: 'cancel' } })}
                    />
                  ))
                )}
              </div>
            </div>
          </div>
        </div>
      ) : (
        <p className="mt-4 text-xs text-slate">Não foi possível carregar a operação do restaurante.</p>
      )}
    </section>
  )
}

function MetricCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-xl border border-border-strong px-4 py-4">
      <p className="text-[11px] font-semibold tracking-wide text-slate uppercase">{label}</p>
      <p className="mt-2 text-2xl font-bold text-cream">{value}</p>
    </div>
  )
}

function WaitlistRow({
  entry,
  onReprioritize,
  onPromote,
  onCancel,
}: {
  entry: RestaurantWaitlistEntry
  onReprioritize: (priority: number) => void
  onPromote: () => void
  onCancel: () => void
}) {
  const [priority, setPriority] = useState(String(entry.priority))

  return (
    <div className="rounded-[12px] border border-border-strong px-3 py-3">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[13px] font-semibold text-cream">
            {entry.guestName} · Quarto {entry.roomNumber}
          </p>
          <p className="mt-1 text-[11.5px] text-slate">
            {entry.partySize} pessoa(s) · {formatUtcDateTime(entry.scheduledFor)}
          </p>
          {entry.tableTypeLabel && <p className="mt-1 text-[11.5px] text-slate">Mesa: {entry.tableTypeLabel}</p>}
          {entry.note && <p className="mt-1 text-[11.5px] italic text-slate">{entry.note}</p>}
        </div>
        <span className="rounded-full bg-gold/10 px-3 py-1 text-[10px] font-bold tracking-wide text-gold-light uppercase">
          {waitlistStatusLabel(entry.status)}
        </span>
      </div>

      <div className="mt-3 flex flex-wrap items-center gap-3">
        <label className="flex items-center gap-2 text-[11.5px] text-slate">
          Prioridade
          <input
            value={priority}
            onChange={(event) => setPriority(event.target.value)}
            type="number"
            min={0}
            max={999}
            className="w-20 rounded-[10px] border border-border-strong bg-surface px-3 py-1.5 text-[12px] text-cream"
          />
        </label>
        <button type="button" onClick={() => onReprioritize(Number(priority))} className="text-[12px] font-semibold text-slate">
          Salvar prioridade
        </button>
        {entry.status === 'waiting' && (
          <>
            <button type="button" onClick={onPromote} className="text-[12px] font-semibold text-gold-light">
              Promover para reserva
            </button>
            <button type="button" onClick={onCancel} className="text-[12px] font-semibold text-[#B3261E]">
              Cancelar fila
            </button>
          </>
        )}
        {entry.promotedReservationId && (
          <span className="text-[11px] text-slate">Reserva gerada: {entry.promotedReservationId}</span>
        )}
      </div>
    </div>
  )
}
