'use client'

import { useState } from 'react'
import { ImageUploadField } from '@/components/ui/ImageUploadField'
import { useServicesPageBanner } from '@/hooks/useServicesPageBanner'

/** Portado de _ServicesPageBannerCard (apps/konekto_portal/lib/features/services/services_list_page.dart). */
export function ServicesPageBannerCard() {
  const { bannerImageUrl, isLoading, error, updateBanner } = useServicesPageBanner()
  const errorMessage = error instanceof Error ? error.message : null

  return (
    <div className="rounded-2xl border border-border-strong bg-surface p-[18px]">
      <h2 className="text-sm font-bold text-cream">Banner da tela de Serviços</h2>
      <p className="mt-1 text-xs text-slate">
        Imagem mostrada no topo da lista de serviços no app do hóspede.
      </p>

      {isLoading ? (
        <div className="mt-3.5 flex justify-center">
          <div className="h-5 w-5 animate-spin rounded-full border-2 border-gold border-t-transparent" />
        </div>
      ) : (
        <div className="mt-3.5 flex flex-col gap-3">
          {errorMessage && (
            <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
              {errorMessage}
            </div>
          )}
          <BannerForm initialImageUrl={bannerImageUrl} onSave={updateBanner} />
        </div>
      )}
    </div>
  )
}

/**
 * Só monta depois que `bannerImageUrl` já carregou (ver ServicesPageBannerCard
 * acima) — o valor inicial do estado local é semeado direto do argumento do
 * `useState`, sem precisar de um efeito pra sincronizar depois.
 */
function BannerForm({
  initialImageUrl,
  onSave,
}: {
  initialImageUrl: string
  onSave: (imageUrl: string) => Promise<void>
}) {
  const [imageUrl, setImageUrl] = useState(initialImageUrl)
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  async function handleSave() {
    setIsSaving(true)
    setSaveError(null)
    try {
      await onSave(imageUrl.trim())
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Falha ao salvar banner.')
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <>
      {saveError && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {saveError}
        </div>
      )}
      <ImageUploadField label="URL da imagem" value={imageUrl} onChange={setImageUrl} />
      <div className="flex justify-end">
        <button
          type="button"
          onClick={handleSave}
          disabled={isSaving}
          className="text-[12.5px] font-semibold text-gold-light disabled:opacity-60"
        >
          {isSaving ? 'Salvando...' : 'Salvar'}
        </button>
      </div>
    </>
  )
}
