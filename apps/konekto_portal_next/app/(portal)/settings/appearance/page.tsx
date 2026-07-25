'use client'

import { useEffect, useState } from 'react'
import { useHotelConfig } from '@/hooks/useHotelConfig'

/**
 * Réplica local (só o essencial pra desenhar a prévia) dos tokens fixos de
 * cada infra do app do hóspede — fonte de verdade é
 * apps/konekto_mobile/lib/theme/guest_infra.dart. Portado de
 * AppearanceSection (apps/konekto_portal/lib/features/settings/
 * appearance_section.dart). A prévia aqui é simplificada (cartão de cores +
 * mockup leve) em vez do mockup pixel-perfect de iPhone do Flutter.
 */
interface InfraOption {
  id: string
  name: string
  tagline: string
  description: string
  bg: string
  card: string
  text: string
  muted: string
  accent: string
  accentSoft: string
}

const INFRA_OPTIONS: InfraOption[] = [
  {
    id: 'amara_bay',
    name: 'Amara Bay',
    tagline: 'RESORT',
    description: 'Boutique quente — terracota e tipografia serifada.',
    bg: '#FBF6EE',
    card: '#FFFFFF',
    text: '#2B2420',
    muted: '#9C8A78',
    accent: '#C1694F',
    accentSoft: '#F1E7D9',
  },
  {
    id: 'verde_pousada',
    name: 'Verde Pousada',
    tagline: 'POUSADA',
    description: 'Editorial sereno — verde sálvia, sem serifa.',
    bg: '#FCFCFA',
    card: '#FFFFFF',
    text: '#293029',
    muted: '#6C7A6E',
    accent: '#5B7F66',
    accentSoft: '#EEF1EC',
  },
]

export default function AppearancePage() {
  const { config, isLoading, error, updateInfra } = useHotelConfig()
  const [selectedInfra, setSelectedInfra] = useState('verde_pousada')
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false)

  useEffect(() => {
    if (!config || hasLoadedOnce) return
    setSelectedInfra(config.infra ?? 'verde_pousada')
    setHasLoadedOnce(true)
  }, [config, hasLoadedOnce])

  async function handleSave() {
    setIsSaving(true)
    setSaveError(null)
    try {
      await updateInfra(selectedInfra)
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
    INFRA_OPTIONS.find((option) => option.id === selectedInfra) ?? INFRA_OPTIONS[1]
  const errorMessage = saveError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-wrap items-start gap-10">
      <div className="w-full max-w-[520px] rounded-2xl border border-border-strong bg-surface p-7">
        <h1 className="text-lg font-bold text-cream">Aparência do app do hóspede</h1>
        <p className="mt-1 text-[12.5px] text-slate">
          Escolha o sistema visual usado nas telas do hóspede — cores, tipografia e layout mudam
          juntos.
        </p>

        {errorMessage && (
          <div className="mt-4 rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
            {errorMessage}
          </div>
        )}

        <div className="mt-6 flex flex-col gap-3">
          {INFRA_OPTIONS.map((option) => {
            const selected = selectedInfra === option.id
            return (
              <button
                key={option.id}
                type="button"
                onClick={() => setSelectedInfra(option.id)}
                className="flex items-center gap-3.5 rounded-[14px] border p-4 text-left"
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
                  <p className="text-sm font-bold text-cream">{option.name}</p>
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
        <PreviewMock option={selectedOption} />
      </div>
    </div>
  )
}

function PreviewMock({ option }: { option: InfraOption }) {
  const tags = ['Serviços', 'Histórico', 'Mapa do local', 'Avisos']
  return (
    <div
      className="w-[260px] rounded-[28px] border p-4"
      style={{ backgroundColor: option.bg, borderColor: option.accentSoft }}
    >
      <p className="text-[9px] font-bold uppercase tracking-wide" style={{ color: option.muted }}>
        Bem-vindo(a) de volta
      </p>
      <p className="mt-1 text-lg font-bold" style={{ color: option.text }}>
        Hóspede
      </p>
      <p className="mt-0.5 text-[11px]" style={{ color: option.muted }}>
        Check-in realizado · Quarto 000
      </p>
      <div
        className="mt-4 flex items-center gap-2 rounded-xl px-3 py-2.5"
        style={{ backgroundColor: option.accentSoft }}
      >
        <span style={{ color: option.accent }}>📶</span>
        <span className="text-[11.5px] font-semibold" style={{ color: option.text }}>
          Wi-Fi &amp; detalhes do quarto
        </span>
      </div>
      <p className="mt-4 text-sm font-bold" style={{ color: option.text }}>
        Nossos serviços
      </p>
      <div className="mt-1 flex flex-col">
        {tags.map((tag, index) => (
          <div
            key={tag}
            className="flex items-center gap-2.5 py-2.5"
            style={{
              borderBottom: index === tags.length - 1 ? 'none' : `1px solid ${option.accentSoft}`,
            }}
          >
            <span style={{ color: option.accent }}>●</span>
            <span className="text-xs font-semibold" style={{ color: option.text }}>
              {tag}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
