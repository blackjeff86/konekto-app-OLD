'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { RoomFormDialog } from '@/components/settings/RoomFormDialog'
import { useRooms } from '@/hooks/useRooms'
import { isRoomOccupied, type Room } from '@/types/room'

/**
 * Cadastro de quartos físicos do hotel — portado de RoomRegistryPage
 * (apps/konekto_portal/lib/features/settings/room_registry_page.dart).
 * Distinto de /rooms (mapa de ocupação): aqui é o cadastro que alimenta
 * aquele mapa e o seletor de quarto ao abrir uma estadia.
 */
export default function RoomRegistryPage() {
  const { rooms, isLoading, error, createRoom, updateRoom, deleteRoom } = useRooms()
  const [editingRoom, setEditingRoom] = useState<Room | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [deletingRoom, setDeletingRoom] = useState<Room | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const isDialogOpen = isCreating || editingRoom !== null

  async function handleSubmit(input: Parameters<typeof createRoom>[0]) {
    if (editingRoom) {
      await updateRoom({ roomId: editingRoom.id, input })
    } else {
      await createRoom(input)
    }
    setIsCreating(false)
    setEditingRoom(null)
  }

  async function handleConfirmDelete() {
    if (!deletingRoom) return
    setActionError(null)
    try {
      await deleteRoom(deletingRoom.id)
      setDeletingRoom(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao remover quarto.')
      setDeletingRoom(null)
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold text-cream">Quartos do hotel</h1>
        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="text-[12.5px] font-semibold text-gold-light"
        >
          + Cadastrar quarto
        </button>
      </div>
      <p className="-mt-3 text-[12.5px] text-slate">
        O cadastro aqui alimenta o mapa de quartos e o seletor de quarto ao abrir uma estadia.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {rooms.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
          Nenhum quarto cadastrado ainda.
        </div>
      ) : (
        <div className="divide-y divide-border-strong rounded-2xl border border-border-strong bg-surface">
          {rooms.map((room) => (
            <RoomRow
              key={room.id}
              room={room}
              onEdit={() => setEditingRoom(room)}
              onDelete={() => setDeletingRoom(room)}
            />
          ))}
        </div>
      )}

      {isDialogOpen && (
        <RoomFormDialog
          existing={editingRoom}
          onClose={() => {
            setIsCreating(false)
            setEditingRoom(null)
          }}
          onSubmit={handleSubmit}
        />
      )}

      {deletingRoom && (
        <Modal
          title="Remover quarto?"
          onClose={() => setDeletingRoom(null)}
          footer={
            <>
              <button type="button" onClick={() => setDeletingRoom(null)} className="text-sm text-slate">
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmDelete} className="text-sm text-[#B3261E]">
                Remover
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            &ldquo;Quarto {deletingRoom.number}&rdquo; será removido permanentemente.
          </p>
        </Modal>
      )}
    </div>
  )
}

function RoomRow({ room, onEdit, onDelete }: { room: Room; onEdit: () => void; onDelete: () => void }) {
  const occupied = isRoomOccupied(room)

  return (
    <div className="flex items-center gap-3.5 px-5 py-3.5">
      <div
        className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[10px] text-base"
        style={{ backgroundColor: occupied ? 'rgba(255,46,136,0.1)' : 'rgba(22,24,29,0.05)' }}
      >
        🚪
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[14.5px] font-bold text-cream">Quarto {room.number}</p>
        {room.description && <p className="truncate text-xs text-slate">{room.description}</p>}
      </div>
      <span
        className="shrink-0 rounded-full px-2.5 py-1 text-[11px] font-semibold"
        style={{
          backgroundColor: occupied ? 'rgba(255,46,136,0.12)' : 'rgba(22,24,29,0.05)',
          color: occupied ? 'var(--color-gold-light)' : 'var(--color-slate-soft)',
        }}
      >
        {occupied ? 'Ocupado' : 'Livre'}
      </span>
      <button type="button" aria-label="Editar" onClick={onEdit} className="shrink-0 text-slate">
        ✎
      </button>
      <button type="button" aria-label="Remover" onClick={onDelete} className="shrink-0 text-slate">
        🗑
      </button>
    </div>
  )
}
