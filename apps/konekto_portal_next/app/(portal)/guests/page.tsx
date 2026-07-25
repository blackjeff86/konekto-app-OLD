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

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold text-cream">Hóspedes</h1>
        <button
          type="button"
          onClick={handleOpenCreate}
          className="text-[12.5px] font-semibold text-gold-light"
        >
          + Criar hóspede
        </button>
      </div>
      <p className="text-[12.5px] text-slate">
        Cada hóspede recebe um código individual pra entrar no app — sem senha, sem cadastro.
        Vários hóspedes do mesmo quarto ficam agrupados na aba Quartos.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {guests.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
          Nenhum hóspede cadastrado ainda.
        </div>
      ) : (
        <div className="divide-y divide-border-strong rounded-2xl border border-border-strong bg-surface">
          {guests.map((guest) => (
            <Link
              key={guest.id}
              href={`/guests/${guest.id}`}
              className="flex items-center gap-3.5 px-5 py-3.5"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-cream">
                  {guest.firstName} {guest.lastName}
                </p>
                <p className="truncate text-xs text-slate">
                  Quarto {guest.stay.roomNumber}  ·  {guest.accessCode}  ·{' '}
                  {formatDate(guest.stay.checkInDate)}–{formatDate(guest.stay.checkOutDate)}
                </p>
              </div>
              <span
                className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-semibold ${
                  guest.status === 'active' ? 'bg-gold/12 text-gold-light' : 'bg-black/5 text-slate-soft'
                }`}
              >
                {guest.status === 'active' ? 'Ativo' : 'Revogado'}
              </span>
              <span className="shrink-0 text-slate">›</span>
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
