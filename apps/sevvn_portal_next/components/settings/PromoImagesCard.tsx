'use client'

import { useEffect, useState } from 'react'
import { ImageUploadField } from '@/components/ui/ImageUploadField'
import { useHotelConfig } from '@/hooks/useHotelConfig'

/** Portado de _PromoImagesCard (apps/konekto_portal/lib/features/settings/settings_page.dart). */
export function PromoImagesCard() {
  const { config, isLoading, error, updatePromoImages } = useHotelConfig()
  const [images, setImages] = useState<string[]>([''])
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false)

  useEffect(() => {
    if (!config || hasLoadedOnce) return
    const loaded = config.hotelInfo?.promoImages?.images ?? []
    setImages(loaded.length > 0 ? loaded : [''])
    setHasLoadedOnce(true)
  }, [config, hasLoadedOnce])

  function updateImageAt(index: number, value: string) {
    setImages((prev) => prev.map((url, i) => (i === index ? value : url)))
  }

  function addRow() {
    setImages((prev) => [...prev, ''])
  }

  function removeRow(index: number) {
    setImages((prev) => prev.filter((_, i) => i !== index))
  }

  async function handleSave() {
    const trimmed = images.map((url) => url.trim()).filter((url) => url.length > 0)
    if (trimmed.length === 0) {
      setSaveError('Adicione pelo menos uma imagem.')
      return
    }
    setIsSaving(true)
    setSaveError(null)
    try {
      const carouselHeight = config?.hotelInfo?.promoImages?.carouselHeight ?? 250
      await updatePromoImages({ images: trimmed, carouselHeight })
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Falha ao salvar carrossel.')
    } finally {
      setIsSaving(false)
    }
  }

  const errorMessage = saveError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="rounded-2xl border border-border-strong bg-surface p-7">
      <h2 className="text-lg font-bold text-cream">Carrossel de destaque</h2>
      <p className="mt-1 text-[12.5px] text-slate">
        Imagens mostradas na tela inicial do hóspede depois que ele entra — use URLs de imagens
        hospedadas (ex: um link direto de foto).
      </p>

      {isLoading ? (
        <div className="mt-6 flex justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
        </div>
      ) : (
        <div className="mt-6 flex flex-col gap-3">
          {errorMessage && (
            <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
              {errorMessage}
            </div>
          )}
          {images.map((url, index) => (
            <div key={index} className="flex items-start gap-2">
              <div className="flex-1">
                <ImageUploadField
                  label={`URL da imagem ${index + 1}`}
                  value={url}
                  onChange={(value) => updateImageAt(index, value)}
                />
              </div>
              <button
                type="button"
                aria-label={`Remover imagem ${index + 1}`}
                onClick={() => removeRow(index)}
                disabled={images.length <= 1}
                className="mt-6 shrink-0 text-slate disabled:opacity-40"
              >
                ✕
              </button>
            </div>
          ))}
          <button
            type="button"
            onClick={addRow}
            className="self-start text-[12.5px] font-semibold text-gold-light"
          >
            + Adicionar imagem
          </button>
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
  )
}
