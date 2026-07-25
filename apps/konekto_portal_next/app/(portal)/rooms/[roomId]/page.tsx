'use client'

import { use } from 'react'
import Link from 'next/link'
import { OccupancyForm } from '@/components/rooms/OccupancyForm'
import { StayDetail } from '@/components/rooms/StayDetail'
import { useRooms } from '@/hooks/useRooms'
import { isRoomOccupied } from '@/types/room'

/**
 * Detalhe de um quarto — portado de rooms_page.dart (que decide, no
 * mesmo lugar, entre StayDetailPage e _FreeRoomDetail conforme
 * room.isOccupied). Aqui isso vira uma rota real por quarto.
 */
export default function RoomDetailPage({ params }: { params: Promise<{ roomId: string }> }) {
  const { roomId } = use(params)
  const { rooms, isLoading, error } = useRooms()

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const room = rooms.find((r) => r.id === roomId)

  if (!room) {
    const message = error instanceof Error ? error.message : 'Quarto não encontrado.'
    return <p className="text-[13.5px] text-cream">{message}</p>
  }

  return (
    <div className="mx-auto flex max-w-[640px] flex-col gap-5">
      <div className="flex items-center gap-3">
        <Link
          href="/rooms"
          aria-label="Voltar"
          className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border text-slate transition-colors hover:bg-surface-alt"
        >
          ←
        </Link>
        <h1 className="flex-1 text-2xl font-extrabold tracking-tight text-cream">Quarto {room.number}</h1>
      </div>

      {isRoomOccupied(room) ? (
        <StayDetail stayId={room.activeStay!.id} />
      ) : (
        <OccupancyForm room={room} />
      )}
    </div>
  )
}
