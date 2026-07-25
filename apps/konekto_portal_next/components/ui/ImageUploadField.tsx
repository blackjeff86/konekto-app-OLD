'use client'

import { useId, useRef, useState } from 'react'
import { API_BASE_URL } from '@/lib/api/client'
import { uploadImage } from '@/lib/api/uploads'
import { useAuth } from '@/lib/auth/AuthProvider'

const ACCEPTED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif']

interface ImageUploadFieldProps {
  label: string
  value: string
  onChange: (url: string) => void
}

/**
 * Campo de imagem compartilhado — portado de
 * apps/konekto_portal/lib/widgets/image_upload_field.dart. Usado em todo
 * formulário que precisa de uma imagem (cupom, logo, banner de serviço,
 * item do cardápio, carrossel promocional).
 *
 * Mantém o campo de URL (staff que já tem uma imagem hospedada em outro
 * lugar pode colar direto) e um botão de upload que sobe o arquivo e
 * preenche a URL sozinho, com preview ao vivo via o endpoint image-proxy
 * (evita CORS e dá suporte a paths de asset legado sem preview).
 */
export function ImageUploadField({ label, value, onChange }: ImageUploadFieldProps) {
  const { session, token } = useAuth()
  const inputId = useId()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [isUploading, setIsUploading] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const isNetworkUrl = value.startsWith('http://') || value.startsWith('https://')

  async function handleFileSelected(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file || !session || !token) return

    if (!ACCEPTED_TYPES.includes(file.type)) {
      setErrorMessage('Formato não suportado — use JPEG, PNG, WebP, GIF ou AVIF.')
      return
    }

    setIsUploading(true)
    setErrorMessage(null)
    try {
      const url = await uploadImage(session.hotelId, token, file)
      onChange(url)
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : 'Falha ao enviar a imagem.')
    } finally {
      setIsUploading(false)
    }
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-start gap-2.5">
        <div className="flex-1">
          <label htmlFor={inputId} className="mb-1 block text-xs text-slate">
            {label}
          </label>
          <input
            id={inputId}
            type="text"
            value={value}
            onChange={(event) => onChange(event.target.value)}
            className="w-full rounded-[10px] border border-border-strong bg-black/3 px-3 py-2.5 text-[13px] text-cream outline-none focus:border-gold"
          />
        </div>
        <button
          type="button"
          disabled={isUploading}
          onClick={() => fileInputRef.current?.click()}
          className="mt-6 h-[46px] shrink-0 rounded-[10px] border border-border-strong px-3 text-[13px] font-medium text-gold-light disabled:opacity-60"
        >
          {isUploading ? 'Enviando...' : 'Enviar imagem'}
        </button>
        <input
          ref={fileInputRef}
          type="file"
          accept={ACCEPTED_TYPES.join(',')}
          className="hidden"
          onChange={handleFileSelected}
        />
      </div>

      {errorMessage && <p className="text-[11.5px] text-[#B3261E]">{errorMessage}</p>}

      {value && (
        <div className="flex h-[120px] items-center justify-center overflow-hidden rounded-[10px] border border-border-strong bg-black/3">
          {isNetworkUrl ? (
            // eslint-disable-next-line @next/next/no-img-element -- imagem de origem dinâmica via proxy do backend
            <img
              src={`${API_BASE_URL}/api/image-proxy?url=${encodeURIComponent(value)}`}
              alt={label}
              className="h-full w-full object-cover"
            />
          ) : (
            <p className="px-4 text-center text-[11.5px] text-slate">
              Essa é uma imagem padrão do sistema, não uma URL — envie um arquivo pra substituir e
              ver o preview.
            </p>
          )}
        </div>
      )}
    </div>
  )
}
