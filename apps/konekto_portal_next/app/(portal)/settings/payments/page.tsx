'use client'

import { useState } from 'react'
import { usePaymentAccount } from '@/hooks/usePaymentAccount'
import type { PaymentAccountStatus } from '@/types/payment'

const STATUS_META: Record<PaymentAccountStatus, { label: string; color: string }> = {
  not_configured: { label: 'Não configurado', color: 'var(--color-slate)' },
  pending: { label: 'Pendente de verificação', color: 'var(--color-gold)' },
  verified: { label: 'Ativo', color: '#5CB85C' },
  rejected: { label: 'Recusado pelo Pagar.me', color: '#DC2626' },
}

/**
 * Pagamento online da conta da estadia (marketplace/split via Pagar.me).
 * Portado de PaymentsSection (apps/konekto_portal/lib/features/settings/
 * payments_section.dart). O KYC completo é feito pelo hotel direto no
 * onboarding do Pagar.me — aqui só colamos e validamos o Recipient ID.
 */
export default function PaymentsPage() {
  const { account, isLoading, error, setRecipientId } = usePaymentAccount()
  const [recipientId, setRecipientIdInput] = useState('')
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  if (account && !hasLoadedOnce) {
    setRecipientIdInput(account.recipientId ?? '')
    setHasLoadedOnce(true)
  }

  async function handleSave() {
    const trimmed = recipientId.trim()
    if (!trimmed) {
      setSaveError('Cole o Recipient ID do Pagar.me.')
      return
    }
    setIsSaving(true)
    setSaveError(null)
    try {
      await setRecipientId(trimmed)
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Falha ao salvar dados de pagamento.')
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

  const status = account?.status ?? 'not_configured'
  const statusMeta = STATUS_META[status]
  const errorMessage = saveError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="mx-auto flex max-w-[520px] flex-col gap-5 rounded-2xl border border-border-strong bg-surface p-7">
      <div>
        <h1 className="text-lg font-bold text-cream">Pagamento online</h1>
        <p className="mt-1 text-[12.5px] text-slate">
          Permite o hóspede pagar a conta da estadia com cartão de crédito de dentro do app. Crie a
          conta de recebedor no onboarding do Pagar.me (dashboard.pagar.me) e cole aqui o Recipient
          ID.
        </p>
      </div>

      <span
        className="inline-flex w-fit items-center gap-2 rounded-full px-3 py-1.5 text-[12.5px] font-semibold"
        style={{ backgroundColor: `${statusMeta.color}24`, color: statusMeta.color }}
      >
        <span className="h-2 w-2 rounded-full" style={{ backgroundColor: statusMeta.color }} />
        {statusMeta.label}
      </span>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <label className="text-xs text-slate">
        Recipient ID do Pagar.me
        <input
          type="text"
          value={recipientId}
          onChange={(event) => setRecipientIdInput(event.target.value)}
          className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
        />
      </label>

      <button
        type="button"
        onClick={handleSave}
        disabled={isSaving}
        className="w-full rounded-full bg-gold py-3 text-sm font-bold text-ink disabled:opacity-60"
      >
        {isSaving ? 'Salvando...' : 'Salvar'}
      </button>
    </div>
  )
}
