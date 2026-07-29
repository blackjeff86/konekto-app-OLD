'use client'

import { useState } from 'react'
import PhoneInput, { parsePhoneNumber } from 'react-phone-number-input'
import 'react-phone-number-input/style.css'
import { SimpleAccessCodeDialog } from '@/components/ui/SimpleAccessCodeDialog'
import { useGuestLookup, useGuests } from '@/hooks/useGuests'
import { useStays } from '@/hooks/useStays'
import {
  documentInputMode,
  documentLabel,
  formatDocumentNumber,
  normalizeDocumentNumber,
} from '@/lib/documentFormat'
import { documentTypeLabel, type DocumentType } from '@/types/guest'
import type { Room } from '@/types/room'

/**
 * Formulário de ocupação de um quarto vago — portado de _FreeRoomDetail
 * (apps/konekto_portal/lib/features/rooms/rooms_page.dart). Busca pelo
 * documento reaproveita o cadastro de quem já se hospedou antes.
 */
export function OccupancyForm({ room }: { room: Room }) {
  const { createStay } = useStays()
  const { createGuest } = useGuests()
  const { lookup, isLoading: isSearching } = useGuestLookup()

  const [checkInDate, setCheckInDate] = useState('')
  const [checkOutDate, setCheckOutDate] = useState('')
  const [documentType, setDocumentType] = useState<DocumentType>('cpf')
  const [documentNumber, setDocumentNumber] = useState('')
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [phone, setPhone] = useState<string>()
  const [whatsappSameAsPhone, setWhatsappSameAsPhone] = useState(true)
  const [whatsapp, setWhatsapp] = useState<string>()
  const [email, setEmail] = useState('')
  const [address, setAddress] = useState('')
  const [country, setCountry] = useState('')
  const [wifiPassword, setWifiPassword] = useState('')
  const [lookupBanner, setLookupBanner] = useState<{ text: string; found: boolean } | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [createdAccessCode, setCreatedAccessCode] = useState<string | null>(null)

  async function handleSearch() {
    const trimmed = normalizeDocumentNumber(documentType, documentNumber)
    if (!trimmed) {
      setErrorMessage('Digite o número do documento pra buscar.')
      return
    }
    setErrorMessage(null)
    setLookupBanner(null)
    try {
      const result = await lookup(trimmed)
      if (!result) {
        setLookupBanner({
          text: 'Nenhum cadastro encontrado com esse documento — preencha os dados de um novo hóspede.',
          found: false,
        })
        return
      }
      setDocumentType(result.documentType)
      setFirstName(result.firstName)
      setLastName(result.lastName)
      setEmail(result.email ?? '')
      setAddress(result.address ?? '')
      setCountry(result.country)
      setPhone(`${result.phoneCountryCode}${result.phoneNumber}`)
      const sameAsPhone =
        result.whatsappNumber == null || result.whatsappNumber === result.phoneNumber
      setWhatsappSameAsPhone(sameAsPhone)
      if (!sameAsPhone && result.whatsappNumber) {
        setWhatsapp(`${result.whatsappCountryCode}${result.whatsappNumber}`)
      }
      setLookupBanner({
        text: `Hóspede encontrado: ${result.firstName} ${result.lastName} — dados preenchidos, revise se necessário.`,
        found: true,
      })
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao buscar hóspede.')
    }
  }

  async function handleSubmit() {
    const trimmedFirstName = firstName.trim()
    const trimmedLastName = lastName.trim()
    const trimmedDocumentNumber = normalizeDocumentNumber(documentType, documentNumber)
    const trimmedCountry = country.trim()

    if (!checkInDate || !checkOutDate) {
      setErrorMessage('Preencha as datas de check-in e check-out.')
      return
    }
    if (checkOutDate < checkInDate) {
      setErrorMessage('A data de saída não pode ser antes da data de entrada.')
      return
    }
    if (
      !trimmedFirstName ||
      !trimmedLastName ||
      !trimmedDocumentNumber ||
      !trimmedCountry ||
      !phone
    ) {
      setErrorMessage('Preencha nome, sobrenome, documento, telefone e país do hóspede.')
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
      const stay = await createStay({ roomId: room.id, checkInDate, checkOutDate })
      const guest = await createGuest({
        stayId: stay.id,
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
      setCreatedAccessCode(guest.accessCode)
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao registrar hóspede.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex flex-col gap-4">
      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <div className="whisper-shadow flex items-center justify-between rounded-xl border border-border bg-surface p-6">
        <p className="text-[13.5px] text-cream">Este quarto está livre.</p>
        <span className="rounded-full border border-border-strong bg-surface px-3 py-1 text-[10px] font-bold tracking-wide text-slate uppercase">
          Livre
        </span>
      </div>
      {room.description && <p className="text-[12.5px] text-slate">{room.description}</p>}

      <h2 className="text-[11px] font-bold tracking-[0.14em] text-slate uppercase">Nova estadia</h2>
      <div className="flex gap-2.5">
        <label className="flex-1 text-xs text-slate">
          Check-in
          <input
            type="date"
            value={checkInDate}
            onChange={(event) => setCheckInDate(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          />
        </label>
        <label className="flex-1 text-xs text-slate">
          Check-out
          <input
            type="date"
            value={checkOutDate}
            onChange={(event) => setCheckOutDate(event.target.value)}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          />
        </label>
      </div>

      <div>
        <h2 className="text-[11px] font-bold tracking-[0.14em] text-slate uppercase">Hóspede</h2>
        <p className="mt-1 text-[12.5px] text-slate">
          Busque pelo documento pra reaproveitar o cadastro de quem já se hospedou antes, ou
          preencha um hóspede novo.
        </p>
      </div>

      <div className="flex items-end gap-2.5">
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
        <label className="flex-1 text-xs text-slate">
          {documentLabel(documentType)}
          <input
            type="text"
            value={documentNumber}
            inputMode={documentInputMode(documentType)}
            maxLength={documentType === 'cpf' ? 14 : documentType === 'other' ? 12 : 12}
            onChange={(event) => setDocumentNumber(formatDocumentNumber(documentType, event.target.value))}
            onBlur={() => documentNumber.trim() && handleSearch()}
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
          />
        </label>
        <button
          type="button"
          onClick={handleSearch}
          disabled={isSearching}
          className="h-[42px] shrink-0 rounded-[10px] border border-border-strong px-3 text-[12.5px] font-medium text-gold-light disabled:opacity-60"
        >
          {isSearching ? 'Buscando...' : 'Buscar'}
        </button>
      </div>

      {lookupBanner && (
        <div
          className={`rounded-[10px] border px-3 py-2.5 text-[12.5px] text-cream ${
            lookupBanner.found ? 'border-gold/35 bg-gold/10' : 'border-slate/35 bg-slate/10'
          }`}
        >
          {lookupBanner.text}
        </div>
      )}

      <div className="flex gap-2.5">
        <Field label="Nome" value={firstName} onChange={setFirstName} />
        <Field label="Sobrenome" value={lastName} onChange={setLastName} />
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

      <button
        type="button"
        onClick={handleSubmit}
        disabled={isSubmitting}
        className="w-full rounded-full bg-gold py-3 text-[13.5px] font-bold text-ink disabled:opacity-60"
      >
        {isSubmitting ? 'Registrando...' : 'Registrar hóspede e iniciar estadia'}
      </button>

      {createdAccessCode && (
        <SimpleAccessCodeDialog accessCode={createdAccessCode} onClose={() => setCreatedAccessCode(null)} />
      )}
    </div>
  )
}

function Field({
  label,
  value,
  onChange,
  type = 'text',
}: {
  label: string
  value: string
  onChange: (value: string) => void
  type?: 'text' | 'email'
}) {
  return (
    <label className="flex-1 text-xs text-slate">
      {label}
      <input
        type={type}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="mt-1 block w-full rounded-[10px] border border-border-strong bg-transparent px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
      />
    </label>
  )
}
