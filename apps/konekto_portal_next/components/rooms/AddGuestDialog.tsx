'use client'

import { useState } from 'react'
import PhoneInput, { parsePhoneNumber } from 'react-phone-number-input'
import 'react-phone-number-input/style.css'
import { Modal } from '@/components/ui/Modal'
import { useGuestLookup } from '@/hooks/useGuests'
import { documentTypeLabel, type DocumentType, type NewGuestInput } from '@/types/guest'

interface AddGuestDialogProps {
  stayId: string
  onClose: () => void
  onSubmit: (input: NewGuestInput) => Promise<void>
}

/**
 * Formulário enxuto pra adicionar um hóspede a uma Stay já conhecida —
 * portado de _AddGuestDialog (apps/konekto_portal/lib/features/rooms/
 * stay_detail_page.dart). Mesmos campos/lookup de OccupancyForm, sem
 * quarto/datas (aqueles moram na Stay, não por pessoa).
 */
export function AddGuestDialog({ stayId, onClose, onSubmit }: AddGuestDialogProps) {
  const { lookup, isLoading: isSearching } = useGuestLookup()

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

  async function handleSearch() {
    const trimmed = documentNumber.trim()
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
    const trimmedDocumentNumber = documentNumber.trim()
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
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao adicionar hóspede.')
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      title="Adicionar hóspede"
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
            Adicionar
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

        <div className="flex gap-2.5">
          <Field label="Nome" value={firstName} onChange={setFirstName} />
          <Field label="Sobrenome" value={lastName} onChange={setLastName} />
        </div>

        <div className="flex items-end gap-2.5">
          <label className="w-32 text-xs text-slate">
            Documento
            <select
              value={documentType}
              onChange={(event) => setDocumentType(event.target.value as DocumentType)}
              className="mt-1 block w-full rounded-[10px] border border-border-strong bg-surface px-3 py-2 text-[13.5px] text-cream outline-none focus:border-gold"
            >
              {(Object.keys(documentTypeLabel) as DocumentType[]).map((type) => (
                <option key={type} value={type}>
                  {documentTypeLabel[type]}
                </option>
              ))}
            </select>
          </label>
          <Field label="Número do documento" value={documentNumber} onChange={setDocumentNumber} />
          <button
            type="button"
            onClick={handleSearch}
            disabled={isSearching}
            className="h-[38px] shrink-0 rounded-[10px] border border-border-strong px-3 text-[12.5px] font-medium text-gold-light disabled:opacity-60"
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

        <label className="text-xs text-slate">
          Telefone
          <PhoneInput
            defaultCountry="BR"
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
              defaultCountry="BR"
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
