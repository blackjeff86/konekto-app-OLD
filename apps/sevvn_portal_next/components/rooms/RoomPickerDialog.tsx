'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import type { Room } from '@/types/room'

/** Portado de _RoomPickerDialog (apps/konekto_portal/lib/features/rooms/stay_detail_page.dart). */
export function RoomPickerDialog({
  rooms,
  onClose,
  onSubmit,
}: {
  rooms: Room[]
  onClose: () => void
  onSubmit: (roomId: string) => Promise<void>
}) {
  const [selectedRoomId, setSelectedRoomId] = useState(rooms[0]?.id ?? '')
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    setIsSubmitting(true)
    try {
      await onSubmit(selectedRoomId)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title="Trocar quarto"
      onClose={onClose}
      footer={
        <>
          <button type="button" onClick={onClose} className="text-sm text-slate">
            Cancelar
          </button>
          <button
            type="button"
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="text-sm font-semibold text-gold-light disabled:opacity-60"
          >
            Mover
          </button>
        </>
      }
    >
      <select
        value={selectedRoomId}
        onChange={(event) => setSelectedRoomId(event.target.value)}
        className="w-full rounded-[10px] border border-border-strong bg-surface px-3 py-2.5 text-[13.5px] text-cream outline-none focus:border-gold"
      >
        {rooms.map((room) => (
          <option key={room.id} value={room.id}>
            Quarto {room.number}
          </option>
        ))}
      </select>
    </Modal>
  )
}
