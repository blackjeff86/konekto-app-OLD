'use client'

import { useEffect, useState } from 'react'
import { ImageUploadField } from '@/components/ui/ImageUploadField'
import { ReceptionQrCard } from '@/components/settings/ReceptionQrCard'
import { WifiSettingsCard } from '@/components/settings/WifiSettingsCard'
import { PromoImagesCard } from '@/components/settings/PromoImagesCard'
import { useHotelConfig } from '@/hooks/useHotelConfig'

/**
 * Aba "Marca" de Configurações — portado de _BrandingSection (apps/
 * konekto_portal/lib/features/settings/settings_page.dart).
 */
export default function BrandingPage() {
  const { config, isLoading, error, updateBranding } = useHotelConfig()
  const [name, setName] = useState('')
  const [logoUrl, setLogoUrl] = useState('')
  const [address, setAddress] = useState('')
  const [guestSubdomain, setGuestSubdomain] = useState('')
  const [customGuestDomain, setCustomGuestDomain] = useState('')
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false)

  useEffect(() => {
    if (!config || hasLoadedOnce) return
    setName(config.hotelInfo?.name ?? '')
    setLogoUrl(config.hotelInfo?.logoUrl ?? '')
    setAddress(config.hotelInfo?.address ?? '')
    setGuestSubdomain(config.hotelInfo?.guestSubdomain ?? '')
    setCustomGuestDomain(config.hotelInfo?.customGuestDomain ?? '')
    setHasLoadedOnce(true)
  }, [config, hasLoadedOnce])

  async function handleSave() {
    setIsSaving(true)
    setSaveError(null)
    try {
      const trimmedName = name.trim()
      const trimmedLogoUrl = logoUrl.trim()
      const trimmedAddress = address.trim()
      const trimmedGuestSubdomain = guestSubdomain.trim().toLowerCase()
      const trimmedCustomGuestDomain = customGuestDomain.trim().toLowerCase()
      await updateBranding({
        name: trimmedName || null,
        logoUrl: trimmedLogoUrl || null,
        address: trimmedAddress || null,
        guestSubdomain: trimmedGuestSubdomain || null,
        customGuestDomain: trimmedCustomGuestDomain || null,
      })
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Falha ao salvar configuração.')
    } finally {
      setIsSaving(false)
    }
  }

  const errorMessage = saveError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-col gap-6">
      <ReceptionQrCard />
      <WifiSettingsCard />
      <PromoImagesCard />

      <div className="rounded-2xl border border-border-strong bg-surface p-7">
        <h2 className="text-lg font-bold text-cream">Marca do hotel</h2>
        <p className="mt-1 text-[12.5px] text-slate">Nome, logo e cores usados no app do hóspede.</p>

        {isLoading ? (
          <div className="mt-6 flex justify-center">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
          </div>
        ) : (
          <div className="mt-6 flex flex-col gap-3.5">
            {errorMessage && (
              <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
                {errorMessage}
              </div>
            )}
            <label className="text-xs text-slate">
              Nome do hotel
              <input
                type="text"
                value={name}
                onChange={(event) => setName(event.target.value)}
                className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
              />
            </label>
            <ImageUploadField label="URL do logo" value={logoUrl} onChange={setLogoUrl} />
            <label className="text-xs text-slate">
              Endereço do hotel
              <input
                type="text"
                value={address}
                onChange={(event) => setAddress(event.target.value)}
                className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
              />
            </label>
            <label className="text-xs text-slate">
              Subdomínio guest na Sevvn
              <input
                type="text"
                value={guestSubdomain}
                onChange={(event) => setGuestSubdomain(event.target.value)}
                placeholder="ex: amara-bay"
                className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
              />
              <span className="mt-1 block text-[11px] text-slate">
                Quando o domínio oficial estiver ativo, poderá responder como `subdominio.sevvn.app`.
              </span>
            </label>
            <label className="text-xs text-slate">
              Domínio customizado do guest
              <input
                type="text"
                value={customGuestDomain}
                onChange={(event) => setCustomGuestDomain(event.target.value)}
                placeholder="ex: app.seuhotel.com.br"
                className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
              />
              <span className="mt-1 block text-[11px] text-slate">
                Opcional. Serve para a Sevvn reconhecer o hotel também por um domínio próprio.
              </span>
            </label>
            <button
              type="button"
              onClick={handleSave}
              disabled={isSaving}
              className="mt-1 w-full rounded-full bg-gold py-3 text-sm font-bold text-ink disabled:opacity-60"
            >
              {isSaving ? 'Salvando...' : 'Salvar'}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
