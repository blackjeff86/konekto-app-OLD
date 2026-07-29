'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import type { Room, RoomInput } from '@/types/room'

interface RoomFormDialogProps {
  existing: Room | null
  onClose: () => void
  onSubmit: (input: RoomInput) => Promise<void>
}

/** Portado de _RoomFormDialog (apps/konekto_portal/lib/features/settings/room_registry_page.dart). */
export function RoomFormDialog({ existing, onClose, onSubmit }: RoomFormDialogProps) {
  const [number, setNumber] = useState(existing?.number ?? '')
  const [description, setDescription] = useState(existing?.description ?? '')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    const trimmedNumber = number.trim()
    if (!trimmedNumber) {
      setErrorMessage('Preencha o número do quarto.')
      return
    }

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      await onSubmit({ number: trimmedNumber, description: description.trim() || null })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao salvar quarto.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title={existing ? 'Editar quarto' : 'Cadastrar quarto'}
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
            Salvar
          </button>
        </>
      }
    >
      <div className="flex flex-col gap-2.5">
        {errorMessage && (
          <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
            {errorMessage}
          </div>
        )}
        <label className="text-xs text-slate">
          Número do quarto
          <input
            type="text"
            value={number}
            onChange={(event) => setNumber(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          />
        </label>
        <label className="text-xs text-slate">
          Descrição (opcional — tipo, comodidades, etc.)
          <textarea
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            rows={3}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          />
        </label>
      </div>
    </Modal>
  )
}
