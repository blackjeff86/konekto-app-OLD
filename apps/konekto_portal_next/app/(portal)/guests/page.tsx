'use client'

import { useState } from 'react'
import Link from 'next/link'
import { GuestFormDialog } from '@/components/guests/GuestFormDialog'
import { AccessCodeDialog } from '@/components/guests/AccessCodeDialog'
import { useGuests } from '@/hooks/useGuests'
import { useStays } from '@/hooks/useStays'
import type { Guest, NewGuestInput } from '@/types/guest'
import { formatDate } from '@/lib/utils/date'

/** Portado de apps/konekto_portal/lib/features/guests/guests_page.dart. */
export default function GuestsPage() {
  const { guests, isLoading, error, createGuest } = useGuests()
  const { stays } = useStays()
  const [isCreating, setIsCreating] = useState(false)
  const [createError, setCreateError] = useState<string | null>(null)
  const [createdGuest, setCreatedGuest] = useState<Guest | null>(null)

  const activeStays = stays.filter((stay) => stay.status === 'active')

  function handleOpenCreate() {
    setCreateError(null)
    if (activeStays.length === 0) {
      setCreateError(
        'Nenhum quarto ocupado ainda — abra um quarto na aba Quartos antes de cadastrar um hóspede.',
      )
      return
    }
    setIsCreating(true)
  }

  async function handleSubmit(input: NewGuestInput) {
    const guest = await createGuest(input)
    setIsCreating(false)
    setCreatedGuest(guest)
  }

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = createError ?? (error instanceof Error ? error.message : null)
  const activeGuestCount = guests.filter((guest) => guest.status === 'active').length

  return (
    <div className="flex flex-col gap-7">
      <div className="flex flex-col items-start justify-between gap-6 md:flex-row md:items-end">
        <div className="max-w-xl">
          <h1 className="text-[28px] font-extrabold tracking-tight text-cream">Hóspedes</h1>
          <p className="mt-2 text-[13.5px] leading-relaxed text-slate">
            Cada hóspede recebe um código individual pra entrar no app — sem senha, sem cadastro.
            Vários hóspedes do mesmo quarto ficam agrupados na aba Quartos.
          </p>
        </div>
        <button
          type="button"
          onClick={handleOpenCreate}
          className="shrink-0 rounded-full bg-ink px-6 py-3 text-[11px] font-bold tracking-[0.1em] text-white uppercase transition-opacity hover:opacity-90"
        >
          + Criar hóspede
        </button>
      </div>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <div className="grid grid-cols-2 gap-5 sm:grid-cols-2">
        <div className="whisper-shadow rounded-xl border border-border bg-surface p-6">
          <p className="text-[10.5px] font-bold tracking-[0.14em] text-slate uppercase">Total cadastrados</p>
          <p className="mt-2 text-3xl font-extrabold tracking-tight text-cream">{guests.length}</p>
        </div>
        <div className="whisper-shadow rounded-xl bg-ink p-6 text-white">
          <p className="text-[10.5px] font-bold tracking-[0.14em] text-white/60 uppercase">Com acesso ativo</p>
          <p className="mt-2 text-3xl font-extrabold tracking-tight">{activeGuestCount}</p>
        </div>
      </div>

      {guests.length === 0 ? (
        <div className="whisper-shadow rounded-xl border border-border bg-surface p-7 text-[13.5px] text-cream">
          Nenhum hóspede cadastrado ainda.
        </div>
      ) : (
        <div className="whisper-shadow hairline-divide overflow-hidden rounded-xl border border-border bg-surface">
          {guests.map((guest) => (
            <Link
              key={guest.id}
              href={`/guests/${guest.id}`}
              className="flex items-center gap-4 px-7 py-5 transition-colors hover:bg-surface-alt"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-cream">
                  {guest.firstName} {guest.lastName}
                </p>
                <p className="mt-0.5 truncate text-xs text-slate">
                  Quarto {guest.stay.roomNumber}  ·  {guest.accessCode}  ·{' '}
                  {formatDate(guest.stay.checkInDate)}–{formatDate(guest.stay.checkOutDate)}
                </p>
              </div>
              <span
                className={`shrink-0 rounded-full px-3 py-1 text-[10px] font-bold tracking-wide uppercase ${
                  guest.status === 'active' ? 'bg-gold/10 text-gold-light' : 'bg-black/5 text-slate-soft'
                }`}
              >
                {guest.status === 'active' ? 'Ativo' : 'Revogado'}
              </span>
              <span className="shrink-0 text-slate-soft">›</span>
            </Link>
          ))}
        </div>
      )}

      {isCreating && (
        <GuestFormDialog
          activeStays={activeStays}
          onClose={() => setIsCreating(false)}
          onSubmit={handleSubmit}
        />
      )}

      {createdGuest && (
        <AccessCodeDialog guest={createdGuest} onClose={() => setCreatedGuest(null)} />
      )}
    </div>
  )
}
