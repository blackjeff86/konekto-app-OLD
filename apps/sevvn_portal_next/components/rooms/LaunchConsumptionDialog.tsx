'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import type { StayGuestSummary } from '@/types/stay'
import type { Service } from '@/types/service'

interface MinibarEntry {
  service: Pick<Service, 'id' | 'name'>
  item: Service['items'][number]
}

interface ConsumptionInput {
  guestId: string
  serviceItemId: string
  quantity: number
}

/** Portado de _LaunchConsumptionDialog (apps/konekto_portal/lib/features/rooms/stay_detail_page.dart). */
export function LaunchConsumptionDialog({
  guests,
  minibarItems,
  onClose,
  onSubmit,
}: {
  guests: StayGuestSummary[]
  minibarItems: MinibarEntry[]
  onClose: () => void
  onSubmit: (input: ConsumptionInput) => Promise<void>
}) {
  const [guestId, setGuestId] = useState(guests[0]?.id ?? '')
  const [serviceItemId, setServiceItemId] = useState(minibarItems[0]?.item.id ?? '')
  const [quantity, setQuantity] = useState(1)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    setIsSubmitting(true)
    try {
      await onSubmit({ guestId, serviceItemId, quantity })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title="Lançar consumo"
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
            Lançar
          </button>
        </>
      }
    >
      <div className="flex flex-col gap-3.5">
        <label className="text-xs text-slate">
          Hóspede
          <select
            value={guestId}
            onChange={(event) => setGuestId(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          >
            {guests.map((guest) => (
              <option key={guest.id} value={guest.id}>
                {guest.firstName} {guest.lastName}
              </option>
            ))}
          </select>
        </label>

        <label className="text-xs text-slate">
          Item de frigobar
          <select
            value={serviceItemId}
            onChange={(event) => setServiceItemId(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          >
            {minibarItems.map(({ item }) => (
              <option key={item.id} value={item.id}>
                {item.price != null ? `${item.name} · R$ ${item.price.toFixed(2)}` : item.name}
              </option>
            ))}
          </select>
        </label>

        <div>
          <p className="text-xs text-slate">Quantidade</p>
          <div className="mt-1 flex items-center gap-3">
            <button
              type="button"
              aria-label="Diminuir"
              onClick={() => setQuantity((q) => Math.max(1, q - 1))}
              disabled={quantity <= 1}
              className="text-lg text-gold-light disabled:opacity-40"
            >
              −
            </button>
            <span className="text-base font-bold text-cream">{quantity}</span>
            <button
              type="button"
              aria-label="Aumentar"
              onClick={() => setQuantity((q) => q + 1)}
              className="text-lg text-gold-light"
            >
              +
            </button>
          </div>
        </div>
      </div>
    </Modal>
  )
}
