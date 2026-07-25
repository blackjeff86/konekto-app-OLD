'use client'

import { useEffect, useState } from 'react'
import { useHotelConfig } from '@/hooks/useHotelConfig'
import { IPhoneMockup } from '@/components/ui/IPhoneMockup'

/**
 * Os 5 templates White Label (Fase 3/Task 7-11) — substituem os 5 antigos
 * (Amara Bay/Verde Pousada/Casa Marechal/Konekto Clássico/Konekto Noturno)
 * como opção do portal. Fonte de verdade de cor/tipografia é
 * apps/konekto_mobile/lib/templates/<id>/theme.dart. A prévia usa o print
 * real da home de cada template exportado do Stitch
 * (public/appearance/*.png), dentro do mesmo mockup de iPhone de antes.
 */
interface TemplateOption {
  id: string
  name: string
  tagline: string
  description: string
  accent: string
  previewImage: string
}

const TEMPLATE_OPTIONS: TemplateOption[] = [
  {
    id: 'aura',
    name: 'Aura',
    tagline: 'ESSENTIAL',
    description: 'Minimalismo sofisticado — roxo suave, Libre Caslon Text e Work Sans.',
    accent: '#4F378A',
    previewImage: '/appearance/aura-home.png',
  },
  {
    id: 'bosque',
    name: 'Bosque',
    tagline: 'ESSENTIAL',
    description: 'Design biofílico — verde-floresta orgânico, Literata e Plus Jakarta Sans.',
    accent: '#173124',
    previewImage: '/appearance/bosque-home.png',
  },
  {
    id: 'elite',
    name: 'Elite',
    tagline: 'PREMIUM',
    description: 'Luxo discreto — preto e dourado sóbrio sobre creme, Playfair Display.',
    accent: '#775A19',
    previewImage: '/appearance/elite-home.png',
  },
  {
    id: 'pulse',
    name: 'Pulse',
    tagline: 'PREMIUM',
    description: 'Glassmorphism tech-luxo — fundo escuro, dourado vibrante, Montserrat.',
    accent: '#D4AF37',
    previewImage: '/appearance/pulse-home.png',
  },
  {
    id: 'horizon',
    name: 'Horizon',
    tagline: 'PREMIUM',
    description: 'Resort costeiro — azul-oceano e laranja-pôr-do-sol, Playfair Display.',
    accent: '#005D90',
    previewImage: '/appearance/horizon-home.png',
  },
]

export default function AppearancePage() {
  const { config, isLoading, error, updateTemplate } = useHotelConfig()
  const [selectedTemplate, setSelectedTemplate] = useState('aura')
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false)

  const allowedTemplates = config?.allowedTemplates ?? []

  useEffect(() => {
    if (!config || hasLoadedOnce) return
    setSelectedTemplate(config.template ?? allowedTemplates[0] ?? 'aura')
    setHasLoadedOnce(true)
  }, [config, hasLoadedOnce, allowedTemplates])

  async function handleSave() {
    setIsSaving(true)
    setSaveError(null)
    try {
      await updateTemplate(selectedTemplate)
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Falha ao salvar aparência.')
    } finally {
      setIsSaving(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const selectedOption =
    TEMPLATE_OPTIONS.find((option) => option.id === selectedTemplate) ?? TEMPLATE_OPTIONS[0]
  const errorMessage = saveError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-wrap items-start gap-10">
      <div className="w-full max-w-[520px] rounded-2xl border border-border-strong bg-surface p-7">
        <h1 className="text-lg font-bold text-cream">Aparência do app do hóspede</h1>
        <p className="mt-1 text-[12.5px] text-slate">
          Escolha o sistema visual usado nas telas do hóspede — cores, tipografia e layout mudam
          juntos.
        </p>

        <div className="mt-4 rounded-[10px] border border-[#D4AF3780] bg-[#D4AF371A] px-3 py-2.5 text-[12.5px] text-[#8A6D1F]">
          Pré-lançamento: a escolha aqui já fica salva, mas os hóspedes ainda veem o app no
          visual atual até a virada oficial destes 5 templates novos.
        </div>

        {errorMessage && (
          <div className="mt-3 rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
            {errorMessage}
          </div>
        )}

        <div className="mt-6 flex flex-col gap-3">
          {TEMPLATE_OPTIONS.map((option) => {
            const selected = selectedTemplate === option.id
            const locked = !allowedTemplates.includes(option.id)
            return (
              <button
                key={option.id}
                type="button"
                disabled={locked}
                onClick={() => setSelectedTemplate(option.id)}
                className="flex items-center gap-3.5 rounded-[14px] border p-4 text-left disabled:cursor-not-allowed disabled:opacity-50"
                style={{
                  borderColor: selected ? option.accent : 'var(--color-border-strong)',
                  backgroundColor: selected ? `${option.accent}1A` : 'rgba(22,24,29,0.03)',
                }}
              >
                <div
                  className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-base font-bold"
                  style={{ backgroundColor: `${option.accent}29`, color: option.accent }}
                >
                  Aa
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold text-cream">{option.name}</p>
                    <span className="rounded-full bg-black/5 px-2 py-0.5 text-[10px] font-semibold tracking-wide text-slate">
                      {option.tagline}
                    </span>
                    {locked && (
                      <span className="rounded-full bg-[#D4AF371A] px-2 py-0.5 text-[10px] font-semibold tracking-wide text-[#8A6D1F]">
                        Disponível no Premium
                      </span>
                    )}
                  </div>
                  <p className="text-[12.5px] text-slate">{option.description}</p>
                </div>
                <span
                  aria-hidden
                  className="shrink-0 text-xl"
                  style={{ color: selected ? option.accent : 'var(--color-slate)' }}
                >
                  {selected ? '●' : '○'}
                </span>
              </button>
            )
          })}
        </div>

        <button
          type="button"
          onClick={handleSave}
          disabled={isSaving}
          className="mt-6 w-full rounded-full bg-gold py-3 text-sm font-bold text-ink disabled:opacity-60"
        >
          {isSaving ? 'Salvando...' : 'Salvar'}
        </button>
      </div>

      <div className="flex flex-1 flex-col items-center gap-4">
        <p className="text-[12.5px] font-semibold text-slate">Prévia — {selectedOption.name}</p>
        <IPhoneMockup
          imageSrc={selectedOption.previewImage}
          imageAlt={`Tela inicial do template ${selectedOption.name}`}
        />
        <p className="max-w-[260px] text-center text-[11px] text-slate-soft">
          Print real da tela do app — role dentro do celular pra ver a página inteira.
        </p>
      </div>
    </div>
  )
}
