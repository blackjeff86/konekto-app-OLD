'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { ImageUploadField } from '@/components/ui/ImageUploadField'
import type { Coupon, CouponDiscountType, CouponInput } from '@/types/coupon'
import { couponDiscountTypeLabel } from '@/types/coupon'

interface CouponFormDialogProps {
  existing: Coupon | null
  onClose: () => void
  onSubmit: (input: CouponInput) => Promise<void>
}

function toDateInputValue(iso: string | null): string {
  return iso ? iso.slice(0, 10) : ''
}

/** Portado de _CouponFormDialog (apps/konekto_portal/lib/features/settings/coupons_page.dart). */
export function CouponFormDialog({ existing, onClose, onSubmit }: CouponFormDialogProps) {
  const [title, setTitle] = useState(existing?.title ?? '')
  const [description, setDescription] = useState(existing?.description ?? '')
  const [code, setCode] = useState(existing?.code ?? '')
  const [imageUrl, setImageUrl] = useState(existing?.imageUrl ?? '')
  const [discountType, setDiscountType] = useState<CouponDiscountType>(
    existing?.discountType ?? 'percentage',
  )
  const [discountValue, setDiscountValue] = useState(existing?.discountValue.toFixed(0) ?? '')
  const [minOrderValue, setMinOrderValue] = useState(
    existing?.minOrderValue?.toFixed(2) ?? '',
  )
  const [usageLimit, setUsageLimit] = useState(existing?.usageLimit?.toString() ?? '')
  const [perGuestLimit, setPerGuestLimit] = useState((existing?.perGuestLimit ?? 1).toString())
  const [validFrom, setValidFrom] = useState(toDateInputValue(existing?.validFrom ?? null))
  const [validUntil, setValidUntil] = useState(toDateInputValue(existing?.validUntil ?? null))
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    const trimmedTitle = title.trim()
    const trimmedDescription = description.trim()
    const trimmedCode = code.trim()
    const parsedDiscountValue = Number.parseFloat(discountValue.replace(',', '.'))

    if (
      !trimmedTitle ||
      !trimmedDescription ||
      !trimmedCode ||
      Number.isNaN(parsedDiscountValue) ||
      parsedDiscountValue <= 0
    ) {
      setErrorMessage('Preencha título, descrição, código e um valor de desconto válido.')
      return
    }
    if (discountType === 'percentage' && parsedDiscountValue > 100) {
      setErrorMessage('Desconto percentual não pode passar de 100%.')
      return
    }

    const parsedMinOrderValue = Number.parseFloat(minOrderValue.replace(',', '.'))
    const parsedUsageLimit = Number.parseInt(usageLimit, 10)
    const parsedPerGuestLimit = Number.parseInt(perGuestLimit, 10)
    const trimmedImageUrl = imageUrl.trim()

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      await onSubmit({
        title: trimmedTitle,
        description: trimmedDescription,
        code: trimmedCode,
        discountType,
        discountValue: parsedDiscountValue,
        minOrderValue: Number.isNaN(parsedMinOrderValue) ? null : parsedMinOrderValue,
        usageLimit: Number.isNaN(parsedUsageLimit) ? null : parsedUsageLimit,
        perGuestLimit:
          Number.isNaN(parsedPerGuestLimit) || parsedPerGuestLimit <= 0 ? 1 : parsedPerGuestLimit,
        imageUrl: trimmedImageUrl || null,
        validFrom: validFrom || null,
        validUntil: validUntil || null,
      })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao salvar cupom.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title={existing ? 'Editar cupom' : 'Criar cupom'}
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

        <Field label="Título" value={title} onChange={setTitle} />
        <Field label="Descrição" value={description} onChange={setDescription} multiline />
        <Field
          label="Código (referência interna, o hóspede não digita)"
          value={code}
          onChange={setCode}
        />
        <ImageUploadField label="URL da imagem (opcional)" value={imageUrl} onChange={setImageUrl} />

        <div>
          <p className="mb-1.5 text-xs text-slate">Tipo de desconto</p>
          <div className="flex flex-wrap gap-2">
            {(Object.keys(couponDiscountTypeLabel) as CouponDiscountType[]).map((type) => (
              <button
                key={type}
                type="button"
                onClick={() => setDiscountType(type)}
                className={`rounded-full px-3 py-1.5 text-[12.5px] font-semibold ${
                  discountType === type ? 'bg-gold text-ink' : 'bg-black/5 text-slate'
                }`}
              >
                {couponDiscountTypeLabel[type]}
              </button>
            ))}
          </div>
        </div>

        <div className="flex gap-2.5">
          <Field
            label={discountType === 'percentage' ? 'Desconto (%)' : 'Desconto (R$)'}
            value={discountValue}
            onChange={setDiscountValue}
            type="number"
          />
          <Field
            label="Pedido mínimo (opcional)"
            value={minOrderValue}
            onChange={setMinOrderValue}
            type="number"
          />
        </div>

        <div className="flex gap-2.5">
          <Field label="Usos por hóspede" value={perGuestLimit} onChange={setPerGuestLimit} type="number" />
          <Field
            label="Limite total (opcional)"
            value={usageLimit}
            onChange={setUsageLimit}
            type="number"
          />
        </div>

        <div className="flex gap-2.5">
          <Field label="Válido a partir de" value={validFrom} onChange={setValidFrom} type="date" />
          <Field label="Válido até" value={validUntil} onChange={setValidUntil} type="date" />
        </div>
      </div>
    </Modal>
  )
}

interface FieldProps {
  label: string
  value: string
  onChange: (value: string) => void
  multiline?: boolean
  type?: 'text' | 'number' | 'date'
}

function Field({ label, value, onChange, multiline, type = 'text' }: FieldProps) {
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
