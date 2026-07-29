'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { ImageUploadField } from '@/components/ui/ImageUploadField'
import { WeekdayChips } from '@/components/ui/WeekdayChips'
import { usePartners } from '@/hooks/usePartners'
import { serviceItemPaymentModeLabel, type ServiceItem, type ServiceItemInput, type ServiceItemPaymentMode, type ServiceType } from '@/types/service'

function minuteFromTime(time: string): number {
  const [hours, minutes] = time.split(':').map(Number)
  return hours * 60 + minutes
}

function timeFromMinute(minute: number | null): string {
  if (minute == null) return ''
  const hours = Math.floor(minute / 60)
    .toString()
    .padStart(2, '0')
  const mins = (minute % 60).toString().padStart(2, '0')
  return `${hours}:${mins}`
}

interface ServiceItemFormDialogProps {
  existing: ServiceItem | null
  serviceType: ServiceType | undefined
  onClose: () => void
  onSubmit: (item: ServiceItemInput) => Promise<void>
}

/** Portado de _ItemFormDialog (apps/konekto_portal/lib/features/services/service_items_page.dart). */
export function ServiceItemFormDialog({ existing, serviceType, onClose, onSubmit }: ServiceItemFormDialogProps) {
  const { partners } = usePartners()

  const [name, setName] = useState(existing?.name ?? '')
  const [description, setDescription] = useState(existing?.description ?? '')
  const [price, setPrice] = useState(existing?.price != null ? String(existing.price) : '')
  const [imageUrl, setImageUrl] = useState(existing?.imageUrl ?? '')
  const [location, setLocation] = useState(existing?.location ?? '')
  const [category, setCategory] = useState(existing?.category ?? '')
  const [extraInfo, setExtraInfo] = useState(existing?.extraInfo ?? '')

  const [schedulingEnabled, setSchedulingEnabled] = useState(existing?.durationMinutes != null)
  const [duration, setDuration] = useState(existing?.durationMinutes != null ? String(existing.durationMinutes) : '')
  const [capacity, setCapacity] = useState(existing?.capacityPerSlot != null ? String(existing.capacityPerSlot) : '')
  const [start, setStart] = useState(timeFromMinute(existing?.availabilityStartMinute ?? null))
  const [end, setEnd] = useState(timeFromMinute(existing?.availabilityEndMinute ?? null))
  const [selectedDays, setSelectedDays] = useState<Set<number>>(new Set(existing?.availableDaysOfWeek ?? []))

  const [isMinibarItem, setIsMinibarItem] = useState(existing?.isMinibarItem ?? false)
  const [partnerId, setPartnerId] = useState(existing?.partnerId ?? '')
  const [paymentMode, setPaymentMode] = useState<ServiceItemPaymentMode>(existing?.paymentMode ?? 'hotel')

  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  function toggleDay(day: number) {
    setSelectedDays((current) => {
      const next = new Set(current)
      if (next.has(day)) next.delete(day)
      else next.add(day)
      return next
    })
  }

  async function handleSubmit() {
    const trimmedName = name.trim()
    if (!trimmedName) {
      setErrorMessage('Informe o nome do item.')
      return
    }

    let durationMinutes: number | null = null
    let capacityPerSlot: number | null = null
    let availableDaysOfWeek: number[] = []
    let availabilityStartMinute: number | null = null
    let availabilityEndMinute: number | null = null

    if (schedulingEnabled) {
      const durationValue = Number(duration)
      const capacityValue = Number(capacity)
      if (!duration || durationValue <= 0) {
        setErrorMessage('Informe uma duração válida (em minutos).')
        return
      }
      if (!capacity || capacityValue <= 0) {
        setErrorMessage('Informe uma capacidade válida por horário.')
        return
      }
      if (selectedDays.size === 0) {
        setErrorMessage('Selecione pelo menos um dia da semana.')
        return
      }
      if (!start || !end) {
        setErrorMessage('Informe o horário de início e fim da disponibilidade.')
        return
      }
      const startMinute = minuteFromTime(start)
      const endMinute = minuteFromTime(end)
      if (endMinute <= startMinute) {
        setErrorMessage('O horário de fim deve ser depois do início.')
        return
      }
      if (durationValue > endMinute - startMinute) {
        setErrorMessage('A duração não cabe na janela de disponibilidade informada.')
        return
      }
      durationMinutes = durationValue
      capacityPerSlot = capacityValue
      availableDaysOfWeek = [...selectedDays].sort((a, b) => a - b)
      availabilityStartMinute = startMinute
      availabilityEndMinute = endMinute
    }

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      await onSubmit({
        name: trimmedName,
        description: description.trim(),
        price: price.trim() ? Number(price) : null,
        imageUrl: imageUrl.trim() || null,
        location: location.trim() || null,
        category: category.trim() || null,
        extraInfo: extraInfo.trim() || null,
        durationMinutes,
        capacityPerSlot,
        availableDaysOfWeek,
        availabilityStartMinute,
        availabilityEndMinute,
        isMinibarItem,
        partnerId: partnerId || null,
        paymentMode: partnerId ? paymentMode : 'hotel',
      })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao salvar item.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title={existing ? 'Editar item' : 'Adicionar item'}
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

        <Field label="Nome do item" value={name} onChange={setName} />
        <Field label="Descrição" value={description} onChange={setDescription} multiline />
        <div className="flex gap-2.5">
          <Field label="Preço (opcional)" value={price} onChange={setPrice} type="number" />
          <Field label="Categoria (opcional)" value={category} onChange={setCategory} />
        </div>
        <div className="flex gap-2.5">
          <Field label="Local (opcional)" value={location} onChange={setLocation} />
          <Field label="Info. extra (opcional)" value={extraInfo} onChange={setExtraInfo} />
        </div>
        <ImageUploadField label="Imagem (opcional)" value={imageUrl} onChange={setImageUrl} />

        {serviceType === 'room_service' && (
          <label className="flex items-center gap-2 text-[12.5px] text-cream">
            <input type="checkbox" checked={isMinibarItem} onChange={(event) => setIsMinibarItem(event.target.checked)} />
            Item de frigobar/minibar (hóspede informa consumo, sem preparo)
          </label>
        )}

        <div className="rounded-[10px] border border-border-strong p-3">
          <label className="flex items-center gap-2 text-[12.5px] text-cream">
            <input
              type="checkbox"
              checked={schedulingEnabled}
              onChange={(event) => setSchedulingEnabled(event.target.checked)}
            />
            Agendamento (hóspede escolhe dia/horário)
          </label>
          {schedulingEnabled && (
            <div className="mt-2.5 flex flex-col gap-2.5">
              <div className="flex gap-2.5">
                <Field label="Duração (min)" value={duration} onChange={setDuration} type="number" />
                <Field label="Capacidade por horário" value={capacity} onChange={setCapacity} type="number" />
              </div>
              <WeekdayChips selectedDays={selectedDays} onToggleDay={toggleDay} />
              <div className="flex gap-2.5">
                <label className="flex-1 text-xs text-slate">
                  Início
                  <input
                    type="time"
                    value={start}
                    onChange={(event) => setStart(event.target.value)}
                    className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
                  />
                </label>
                <label className="flex-1 text-xs text-slate">
                  Fim
                  <input
                    type="time"
                    value={end}
                    onChange={(event) => setEnd(event.target.value)}
                    className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
                  />
                </label>
              </div>
            </div>
          )}
        </div>

        <label className="text-xs text-slate">
          Parceiro prestador (opcional)
          <select
            value={partnerId}
            onChange={(event) => setPartnerId(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          >
            <option value="">O próprio hotel presta</option>
            {partners.map((partner) => (
              <option key={partner.id} value={partner.id}>
                {partner.name}
              </option>
            ))}
          </select>
        </label>
        {partnerId && (
          <label className="text-xs text-slate">
            Cobrança
            <select
              value={paymentMode}
              onChange={(event) => setPaymentMode(event.target.value as ServiceItemPaymentMode)}
              className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
            >
              <option value="hotel">{serviceItemPaymentModeLabel.hotel}</option>
              <option value="partner">{serviceItemPaymentModeLabel.partner}</option>
            </select>
          </label>
        )}
      </div>
    </Modal>
  )
}

function Field({
  label,
  value,
  onChange,
  multiline,
  type = 'text',
}: {
  label: string
  value: string
  onChange: (value: string) => void
  multiline?: boolean
  type?: 'text' | 'number'
}) {
  const baseClasses =
    'w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold'
  return (
    <label className="flex-1 text-xs text-slate">
      {label}
      {multiline ? (
        <textarea
          value={value}
          onChange={(event) => onChange(event.target.value)}
          rows={2}
          className={`${baseClasses} mt-1 block`}
        />
      ) : (
        <input
          type={type}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          className={`${baseClasses} mt-1 block`}
        />
      )}
    </label>
  )
}
