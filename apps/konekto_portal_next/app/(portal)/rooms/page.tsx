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
    <div className="flex flex-col gap-4">
      <h1 className="text-lg font-bold text-cream">Quartos</h1>
      <p className="text-[12.5px] text-slate">
        Toque num quarto vago pra registrar um hóspede e iniciar a estadia — ou num quarto ocupado
        pra ver hóspedes, avisos e o valor em aberto.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {rooms.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
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
    <section className="flex flex-col gap-3">
      <div className="flex items-center gap-2">
        <h2 className="text-[15px] font-bold text-cream">{title}</h2>
        <span className="rounded-full bg-black/5 px-2 py-0.5 text-[11.5px] font-semibold text-slate">
          {rooms.length}
        </span>
      </div>
      {rooms.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-5 text-[13px] text-cream">
          Nenhum quarto nessa situação agora.
        </div>
      ) : (
        <div className="flex flex-wrap gap-3">
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
      className={`w-[172px] rounded-2xl border p-4 ${
        occupied ? 'border-gold/50' : 'border-border-strong'
      } bg-surface`}
    >
      <div className="flex items-center justify-between">
        <span className={occupied ? 'text-gold-light' : 'text-slate'}>{occupied ? '🛏' : '🚪'}</span>
        <span
          className={`rounded-full px-2 py-0.5 text-[10.5px] font-semibold ${
            occupied ? 'bg-gold/14 text-gold-light' : 'bg-black/5 text-slate-soft'
          }`}
        >
          {occupied ? 'Ocupado' : 'Livre'}
        </span>
      </div>
      <p className="mt-3 text-[15px] font-bold text-cream">Quarto {room.number}</p>
      {occupied && room.activeStay ? (
        <>
          <p className="mt-1 text-xs text-slate">
            {room.activeStay.guestCount} hóspede{room.activeStay.guestCount === 1 ? '' : 's'}
          </p>
          <p className="mt-1 text-[12.5px] font-semibold text-gold-light">
            R$ {room.activeStay.consumptionTotal.toFixed(2)}
          </p>
        </>
      ) : (
        room.description && <p className="mt-1 line-clamp-2 text-xs text-slate">{room.description}</p>
      )}
    </Link>
  )
}
