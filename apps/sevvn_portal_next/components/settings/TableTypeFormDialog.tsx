'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import type { RestaurantTableType } from '@/types/service'
import type { TableTypeInput } from '@/lib/api/services'

interface TableTypeFormDialogProps {
  existing: RestaurantTableType | null
  onClose: () => void
  onSubmit: (input: TableTypeInput) => Promise<void>
}

/** Portado de _TableTypeFormDialog (apps/konekto_portal/lib/features/services/service_items_page.dart). */
export function TableTypeFormDialog({ existing, onClose, onSubmit }: TableTypeFormDialogProps) {
  const [label, setLabel] = useState(existing?.label ?? '')
  const [seats, setSeats] = useState(existing ? String(existing.seats) : '')
  const [quantity, setQuantity] = useState(existing ? String(existing.quantity) : '')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    const seatsValue = Number(seats)
    const quantityValue = Number(quantity)
    if (!seats || seatsValue <= 0) {
      setErrorMessage('Informe quantos lugares por mesa.')
      return
    }
    if (!quantity || quantityValue <= 0) {
      setErrorMessage('Informe quantas mesas desse tipo o restaurante tem.')
      return
    }

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      await onSubmit({ label: label.trim() || null, seats: seatsValue, quantity: quantityValue })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao salvar tipo de mesa.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title={existing ? 'Editar tipo de mesa' : 'Adicionar tipo de mesa'}
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
          Rótulo (opcional)
          <input
            type="text"
            value={label}
            onChange={(event) => setLabel(event.target.value)}
            placeholder='ex: "Mesa de varanda"'
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          />
        </label>
        <div className="flex gap-2.5">
          <label className="flex-1 text-xs text-slate">
            Lugares por mesa
            <input
              type="number"
              value={seats}
              onChange={(event) => setSeats(event.target.value)}
              className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
            />
          </label>
          <label className="flex-1 text-xs text-slate">
            Quantidade de mesas
            <input
              type="number"
              value={quantity}
              onChange={(event) => setQuantity(event.target.value)}
              className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
            />
          </label>
        </div>
      </div>
    </Modal>
  )
}
