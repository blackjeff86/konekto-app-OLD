'use client'

import { useEffect, useState } from 'react'
import { useWifiSettings } from '@/hooks/useWifiSettings'

/** Portado de _WifiSettingsCard (apps/konekto_portal/lib/features/settings/settings_page.dart). */
export function WifiSettingsCard() {
  const { wifi, isLoading, error, updateWifi } = useWifiSettings()
  const [networkName, setNetworkName] = useState('')
  const [password, setPassword] = useState('')
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  useEffect(() => {
    setNetworkName(wifi.networkName)
    setPassword(wifi.password)
  }, [wifi.networkName, wifi.password])

  async function handleSave() {
    setIsSaving(true)
    setSaveError(null)
    try {
      await updateWifi({ networkName: networkName.trim(), password: password.trim() })
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Falha ao salvar wifi.')
    } finally {
      setIsSaving(false)
    }
  }

  const errorMessage = saveError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="rounded-2xl border border-border-strong bg-surface p-7">
      <h2 className="text-lg font-bold text-cream">Wi-Fi padrão</h2>
      <p className="mt-1 text-[12.5px] text-slate">
        Mostrado pro hóspede na tela inicial — a recepção pode dar uma senha diferente pra um
        hóspede específico no cadastro dele.
      </p>

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
          <Field label="Nome da rede" value={networkName} onChange={setNetworkName} />
          <Field label="Senha padrão" value={password} onChange={setPassword} />
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

function Field({
  label,
  value,
  onChange,
}: {
  label: string
  value: string
  onChange: (value: string) => void
}) {
  return (
    <label className="text-xs text-slate">
      {label}
      <input
        type="text"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
      />
    </label>
  )
}
