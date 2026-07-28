'use client'

import { useState } from 'react'
import { useHotelConfig } from '@/hooks/useHotelConfig'
import { useModulesCatalog } from '@/hooks/useModulesCatalog'
import {
  MODULE_CATEGORY_LABELS,
  MODULE_OPERATION_MODE_LABELS,
  type ModuleCategory,
  type ModuleDefinition,
} from '@/types/moduleCatalog'

const CATEGORY_ORDER: ModuleCategory[] = ['core', 'hospitalidade', 'financeiro', 'experiencia', 'comunicacao']

/**
 * Módulos do app do hóspede — Fase 4 da arquitetura de Módulos (ver
 * tasks/plan.md). Primeira tela em que o PRÓPRIO hotel liga/desliga algo
 * (antes disso só a equipe Sevvn tinha esse controle, via konekto_admin,
 * e só pra flags de cortesia). Um módulo ausente de `enabledModules`
 * (vindo do GET) não está disponível pro plano do hotel de jeito nenhum —
 * aparece travado aqui, igual ao padrão já usado em /settings/appearance
 * pros templates fora do plano.
 */
export default function ModulesPage() {
  const { config, isLoading: isLoadingConfig, updateModuleEnabled } = useHotelConfig()
  const { modules, isLoading: isLoadingCatalog } = useModulesCatalog()
  const [pendingModuleId, setPendingModuleId] = useState<string | null>(null)
  const [errorByModuleId, setErrorByModuleId] = useState<Record<string, string>>({})

  const isLoading = isLoadingConfig || isLoadingCatalog

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const resolvedById = new Map((config?.enabledModules ?? []).map((module) => [module.id, module]))

  async function handleToggle(moduleId: string, nextEnabled: boolean) {
    setPendingModuleId(moduleId)
    setErrorByModuleId((prev) => ({ ...prev, [moduleId]: '' }))
    try {
      await updateModuleEnabled({ moduleId, enabled: nextEnabled })
    } catch (err) {
      setErrorByModuleId((prev) => ({
        ...prev,
        [moduleId]: err instanceof Error ? err.message : 'Falha ao salvar módulo.',
      }))
    } finally {
      setPendingModuleId(null)
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-lg font-bold text-cream">Módulos</h1>
        <p className="mt-1 text-[12.5px] text-slate">
          Ligue ou desligue o que seu hotel oferece — o que estiver desligado some da Home, do
          menu de Serviços e da navegação do hóspede automaticamente, sem precisar mexer em
          nenhuma tela.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {CATEGORY_ORDER.map((category) => {
          const categoryModules = modules
            .filter((module) => module.category === category)
            .sort((a, b) => a.defaultOrder - b.defaultOrder)
          if (categoryModules.length === 0) return null

          return (
            <div key={category} className="rounded-2xl border border-border-strong bg-surface p-7">
              <h2 className="text-sm font-bold text-cream">{MODULE_CATEGORY_LABELS[category]}</h2>
              <div className="mt-4 flex flex-col gap-3">
                {categoryModules.map((module) => (
                  <ModuleRow
                    key={module.id}
                    module={module}
                    resolved={resolvedById.get(module.id) ?? null}
                    isPending={pendingModuleId === module.id}
                    error={errorByModuleId[module.id]}
                    onToggle={(enabled) => handleToggle(module.id, enabled)}
                  />
                ))}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

function ModuleRow({
  module,
  resolved,
  isPending,
  error,
  onToggle,
}: {
  module: ModuleDefinition
  resolved: { enabled: boolean } | null
  isPending: boolean
  error?: string
  onToggle: (enabled: boolean) => void
}) {
  const locked = resolved === null

  return (
    <div className="flex flex-col gap-1.5 border-t border-border-strong pt-3 first:border-t-0 first:pt-0">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <p className="text-[13px] font-semibold text-cream">{module.name}</p>
            <span className="rounded-full bg-[#F4E7C633] px-2 py-0.5 text-[10px] font-semibold tracking-wide text-[#8A6D1F]">
              {MODULE_OPERATION_MODE_LABELS[module.operationMode]}
            </span>
            {locked && (
              <span className="rounded-full bg-[#D4AF371A] px-2 py-0.5 text-[10px] font-semibold tracking-wide text-[#8A6D1F]">
                Disponível no Premium
              </span>
            )}
            {!module.implemented && (
              <span className="rounded-full bg-black/5 px-2 py-0.5 text-[10px] font-semibold tracking-wide text-slate">
                Em breve
              </span>
            )}
          </div>
          <p className="text-[12px] text-slate">{module.description}</p>
        </div>

        {!locked && module.implemented && (
          <ToggleSwitch checked={resolved!.enabled} disabled={isPending} onChange={onToggle} />
        )}
      </div>
      {error && <p className="text-[11.5px] text-[#B3261E]">{error}</p>}
    </div>
  )
}

function ToggleSwitch({
  checked,
  disabled,
  onChange,
}: {
  checked: boolean
  disabled: boolean
  onChange: (checked: boolean) => void
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className="relative h-6 w-11 shrink-0 rounded-full transition-colors disabled:opacity-60"
      style={{ backgroundColor: checked ? 'var(--color-gold)' : 'var(--color-border-strong)' }}
    >
      <span
        className="absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform"
        style={{ transform: checked ? 'translateX(22px)' : 'translateX(2px)' }}
      />
    </button>
  )
}
