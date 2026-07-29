'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import type { Partner, PartnerInput } from '@/types/partner'

interface PartnerFormDialogProps {
  existing: Partner | null
  onClose: () => void
  onSubmit: (input: PartnerInput) => Promise<void>
}

/** Portado de _PartnerFormDialog (apps/konekto_portal/lib/features/settings/partners_page.dart). */
export function PartnerFormDialog({ existing, onClose, onSubmit }: PartnerFormDialogProps) {
  const [name, setName] = useState(existing?.name ?? '')
  const [contactName, setContactName] = useState(existing?.contactName ?? '')
  const [phone, setPhone] = useState(existing?.phone ?? '')
  const [email, setEmail] = useState(existing?.email ?? '')
  const [notes, setNotes] = useState(existing?.notes ?? '')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    const trimmedName = name.trim()
    if (!trimmedName) {
      setErrorMessage('Informe o nome do parceiro.')
      return
    }

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      await onSubmit({
        name: trimmedName,
        contactName: contactName.trim() || null,
        phone: phone.trim() || null,
        email: email.trim() || null,
        notes: notes.trim() || null,
      })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao salvar parceiro.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title={existing ? 'Editar parceiro' : 'Cadastrar parceiro'}
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

        <Field label="Nome do parceiro" value={name} onChange={setName} />
        <Field label="Pessoa de contato (opcional)" value={contactName} onChange={setContactName} />
        <div className="flex gap-2.5">
          <Field label="Telefone (opcional)" value={phone} onChange={setPhone} />
          <Field label="E-mail (opcional)" value={email} onChange={setEmail} />
        </div>
        <Field label="Observações (opcional)" value={notes} onChange={setNotes} multiline />
      </div>
    </Modal>
  )
}

function Field({
  label,
  value,
  onChange,
  multiline,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  multiline?: boolean
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
          type="text"
          value={value}
          onChange={(event) => onChange(event.target.value)}
          className={`${baseClasses} mt-1 block`}
        />
      )}
    </label>
  )
}
