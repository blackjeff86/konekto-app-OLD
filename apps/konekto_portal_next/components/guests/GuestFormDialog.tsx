'use client'

import { useState } from 'react'
import PhoneInput, { parsePhoneNumber } from 'react-phone-number-input'
import 'react-phone-number-input/style.css'
import { Modal } from '@/components/ui/Modal'
import {
  documentInputMode,
  documentLabel,
  formatDocumentNumber,
  normalizeDocumentNumber,
} from '@/lib/documentFormat'
import { documentTypeLabel, type DocumentType, type NewGuestInput } from '@/types/guest'
import type { Stay } from '@/types/stay'

interface GuestFormDialogProps {
  activeStays: Stay[]
  onClose: () => void
  onSubmit: (input: NewGuestInput) => Promise<void>
}

/** Portado de _GuestFormDialog (apps/konekto_portal/lib/features/guests/guests_page.dart). */
export function GuestFormDialog({ activeStays, onClose, onSubmit }: GuestFormDialogProps) {
  const [stayId, setStayId] = useState(activeStays[0]?.id ?? '')
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [documentType, setDocumentType] = useState<DocumentType>('cpf')
  const [documentNumber, setDocumentNumber] = useState('')
  const [phone, setPhone] = useState<string>()
  const [whatsappSameAsPhone, setWhatsappSameAsPhone] = useState(true)
  const [whatsapp, setWhatsapp] = useState<string>()
  const [email, setEmail] = useState('')
  const [address, setAddress] = useState('')
  const [country, setCountry] = useState('')
  const [wifiPassword, setWifiPassword] = useState('')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit() {
    const trimmedFirstName = firstName.trim()
    const trimmedLastName = lastName.trim()
    const trimmedDocumentNumber = normalizeDocumentNumber(documentType, documentNumber)
    const trimmedCountry = country.trim()

    if (!trimmedFirstName || !trimmedLastName || !trimmedDocumentNumber || !trimmedCountry || !phone) {
      setErrorMessage('Preencha nome, sobrenome, documento, telefone e país.')
      return
    }

    const parsedPhone = parsePhoneNumber(phone)
    if (!parsedPhone) {
      setErrorMessage('Telefone inválido.')
      return
    }

    const whatsappValue = whatsappSameAsPhone ? phone : whatsapp
    const parsedWhatsapp = whatsappValue ? parsePhoneNumber(whatsappValue) : undefined

    setIsSubmitting(true)
    setErrorMessage(null)
    try {
      await onSubmit({
        stayId,
        firstName: trimmedFirstName,
        lastName: trimmedLastName,
        documentType,
        documentNumber: trimmedDocumentNumber,
        phoneCountryCode: `+${parsedPhone.countryCallingCode}`,
        phoneNumber: parsedPhone.nationalNumber,
        whatsappCountryCode: parsedWhatsapp ? `+${parsedWhatsapp.countryCallingCode}` : undefined,
        whatsappNumber: parsedWhatsapp?.nationalNumber,
        email: email.trim() || undefined,
        address: address.trim() || undefined,
        country: trimmedCountry,
        wifiPassword: wifiPassword.trim() || undefined,
      })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao criar hóspede.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title="Criar hóspede"
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
            Criar
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
          Quarto
          <select
            value={stayId}
            onChange={(event) => setStayId(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          >
            {activeStays.map((stay) => (
              <option key={stay.id} value={stay.id}>
                Quarto {stay.roomNumber} ({stay.guests.length} hóspede
                {stay.guests.length === 1 ? '' : 's'})
              </option>
            ))}
          </select>
        </label>

        <div className="flex gap-2.5">
          <Field label="Nome" value={firstName} onChange={setFirstName} />
          <Field label="Sobrenome" value={lastName} onChange={setLastName} />
        </div>

        <div className="flex gap-2.5">
          <label className="w-36 text-xs text-slate">
            Documento
            <select
              value={documentType}
              onChange={(event) => {
                const nextType = event.target.value as DocumentType
                setDocumentType(nextType)
                setDocumentNumber(formatDocumentNumber(nextType, documentNumber))
              }}
              className="mt-1 block w-full rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
            >
              {(Object.keys(documentTypeLabel) as DocumentType[]).map((type) => (
                <option key={type} value={type}>
                  {documentTypeLabel[type]}
                </option>
              ))}
            </select>
          </label>
          <Field
            label={documentLabel(documentType)}
            value={documentNumber}
            onChange={(value) => setDocumentNumber(formatDocumentNumber(documentType, value))}
            inputMode={documentInputMode(documentType)}
            maxLength={documentType === 'cpf' ? 14 : documentType === 'other' ? 12 : 12}
          />
        </div>

        <label className="text-xs text-slate">
          Telefone
          <PhoneInput
            country="BR"
            international={false}
            limitMaxLength
            value={phone}
            onChange={setPhone}
            className="mt-1 [&_input]:rounded-[10px] [&_input]:border [&_input]:border-border-strong [&_input]:bg-transparent [&_input]:px-3 [&_input]:py-2 [&_input]:text-[13.5px] [&_input]:text-cream [&_input]:outline-none"
          />
        </label>

        <label className="flex items-center gap-2 text-[12.5px] text-slate">
          <input
            type="checkbox"
            checked={whatsappSameAsPhone}
            onChange={(event) => setWhatsappSameAsPhone(event.target.checked)}
            className="accent-gold"
          />
          WhatsApp é o mesmo número do telefone
        </label>

        {!whatsappSameAsPhone && (
          <label className="text-xs text-slate">
            WhatsApp
            <PhoneInput
              country="BR"
              international={false}
              limitMaxLength
              value={whatsapp}
              onChange={setWhatsapp}
              className="mt-1 [&_input]:rounded-[10px] [&_input]:border [&_input]:border-border-strong [&_input]:bg-transparent [&_input]:px-3 [&_input]:py-2 [&_input]:text-[13.5px] [&_input]:text-cream [&_input]:outline-none"
            />
          </label>
        )}

        <Field label="E-mail (opcional)" value={email} onChange={setEmail} type="email" />
        <Field label="Endereço (opcional)" value={address} onChange={setAddress} />
        <Field label="País" value={country} onChange={setCountry} />
        <Field
          label="Senha de wifi (opcional — vazio usa a padrão do hotel)"
          value={wifiPassword}
          onChange={setWifiPassword}
        />
      </div>
    </Modal>
  )
}

function Field({
  label,
  value,
  onChange,
  type = 'text',
  inputMode,
  maxLength,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  type?: 'text' | 'email'
  inputMode?: 'text' | 'numeric'
  maxLength?: number
}) {
  return (
    <label className="flex-1 text-xs text-slate">
      {label}
      <input
        type={type}
        value={value}
        inputMode={inputMode}
        maxLength={maxLength}
        onChange={(event) => onChange(event.target.value)}
        className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
      />
    </label>
  )
}
