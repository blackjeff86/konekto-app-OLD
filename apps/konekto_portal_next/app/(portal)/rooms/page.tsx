'use client'

import Link from 'next/link'
import { useRooms } from '@/hooks/useRooms'
import { isRoomOccupied, type Room } from '@/types/room'

/** Portado de apps/konekto_portal/lib/features/rooms/rooms_page.dart. */
export default function RoomsPage() {
  const { rooms, isLoading, error } = useRooms()

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = error instanceof Error ? error.message : null
  const freeRooms = rooms.filter((room) => !isRoomOccupied(room))
  const occupiedRooms = rooms.filter((room) => isRoomOccupied(room))

  return (
    <div className="flex flex-col gap-8">
      <div className="flex flex-col items-start justify-between gap-6 md:flex-row md:items-end">
        <div className="max-w-xl">
          <h1 className="text-[28px] font-extrabold tracking-tight text-cream">Quartos</h1>
          <p className="mt-2 text-[13.5px] leading-relaxed text-slate">
            Toque num quarto vago pra registrar um hóspede e iniciar a estadia — ou num quarto
            ocupado pra ver hóspedes, avisos e o valor em aberto.
          </p>
        </div>
        <div className="flex shrink-0 gap-5 rounded-xl border border-border bg-surface px-6 py-4">
          <span className="flex items-center gap-2 text-[10.5px] font-bold tracking-wide text-slate uppercase">
            <span className="h-2 w-2 rounded-full bg-gold" /> Legenda: ocupado
          </span>
          <span className="flex items-center gap-2 text-[10.5px] font-bold tracking-wide text-slate uppercase">
            <span className="h-2 w-2 rounded-full border border-border-strong bg-surface-alt" /> Legenda: livre
          </span>
        </div>
      </div>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {rooms.length === 0 ? (
        <div className="whisper-shadow rounded-xl border border-border bg-surface p-7 text-[13.5px] text-cream">
          Nenhum quarto cadastrado ainda — cadastre em Configurações → Quartos.
        </div>
      ) : (
        <>
          <RoomSection title="Quartos vagos" rooms={freeRooms} />
          <RoomSection title="Quartos ocupados" rooms={occupiedRooms} />
        </>
      )}
    </div>
  )
}

function RoomSection({ title, rooms }: { title: string; rooms: Room[] }) {
  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-baseline gap-3 border-b border-border pb-3">
        <h2 className="text-lg font-bold text-cream">{title}</h2>
        <span className="text-[11px] font-bold tracking-wide text-slate-soft uppercase">{rooms.length}</span>
      </div>
      {rooms.length === 0 ? (
        <div className="whisper-shadow rounded-xl border border-border bg-surface p-5 text-[13px] text-cream">
          Nenhum quarto nessa situação agora.
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {rooms.map((room) => (
            <RoomCard key={room.id} room={room} />
          ))}
        </div>
      )}
    </section>
  )
}

function RoomCard({ room }: { room: Room }) {
  const occupied = isRoomOccupied(room)
  return (
    <Link
      href={`/rooms/${room.id}`}
      className={`whisper-shadow rounded-xl border p-6 transition-transform hover:-translate-y-0.5 ${
        occupied ? 'border-border bg-surface' : 'border-border bg-surface-alt/60'
      }`}
    >
      <div className="flex items-start justify-between">
        <span className={`text-lg font-extrabold tracking-tight ${occupied ? 'text-cream' : 'text-slate-soft'}`}>
          Quarto {room.number}
        </span>
        <span
          className={`rounded-full px-2.5 py-1 text-[9.5px] font-bold tracking-wide uppercase ${
            occupied ? 'bg-gold text-white' : 'border border-border-strong bg-surface text-slate'
          }`}
        >
          {occupied ? 'Ocupado' : 'Livre'}
        </span>
      </div>
      {occupied && room.activeStay ? (
        <>
          <p className="mt-4 text-[10px] font-bold tracking-wide text-slate uppercase">
            {room.activeStay.guestCount} hóspede{room.activeStay.guestCount === 1 ? '' : 's'}
          </p>
          <p className="mt-1 text-[13px] font-bold text-gold-light">
            R$ {room.activeStay.consumptionTotal.toFixed(2)}
          </p>
        </>
      ) : (
        <p className="mt-4 text-[11px] text-slate">
          {room.description || 'Pronto para receber um hóspede'}
        </p>
      )}
    </Link>
  )
}
