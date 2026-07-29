'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { PartnerFormDialog } from '@/components/settings/PartnerFormDialog'
import { usePartners } from '@/hooks/usePartners'
import type { Partner } from '@/types/partner'

/** Portado de apps/konekto_portal/lib/features/settings/partners_page.dart. */
export default function PartnersPage() {
  const { partners, isLoading, error, createPartner, updatePartner, deletePartner } = usePartners()
  const [editingPartner, setEditingPartner] = useState<Partner | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [deletingPartner, setDeletingPartner] = useState<Partner | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const isDialogOpen = isCreating || editingPartner !== null

  async function handleSubmit(input: Parameters<typeof createPartner>[0]) {
    if (editingPartner) {
      await updatePartner({ partnerId: editingPartner.id, input })
    } else {
      await createPartner(input)
    }
    setIsCreating(false)
    setEditingPartner(null)
  }

  async function handleConfirmDelete() {
    if (!deletingPartner) return
    setActionError(null)
    try {
      await deletePartner(deletingPartner.id)
      setDeletingPartner(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao remover parceiro.')
      setDeletingPartner(null)
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold text-cream">Parceiros</h1>
        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="text-[12.5px] font-semibold text-gold-light"
        >
          + Cadastrar parceiro
        </button>
      </div>
      <p className="text-[12.5px] text-slate">
        Empresas que prestam algum serviço do hotel (ex: um estúdio de massagem terceirizado).
        Vincule um parceiro a um item em Serviços pra decidir se o pagamento é cobrado pelo
        Sevvn ou direto com o parceiro.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {partners.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
          Nenhum parceiro cadastrado ainda.
        </div>
      ) : (
        <div className="divide-y divide-border-strong rounded-2xl border border-border-strong bg-surface">
          {partners.map((partner) => (
            <PartnerRow
              key={partner.id}
              partner={partner}
              onEdit={() => setEditingPartner(partner)}
              onDelete={() => setDeletingPartner(partner)}
            />
          ))}
        </div>
      )}

      {isDialogOpen && (
        <PartnerFormDialog
          existing={editingPartner}
          onClose={() => {
            setIsCreating(false)
            setEditingPartner(null)
          }}
          onSubmit={handleSubmit}
        />
      )}

      {deletingPartner && (
        <Modal
          title="Remover parceiro?"
          onClose={() => setDeletingPartner(null)}
          footer={
            <>
              <button
                type="button"
                onClick={() => setDeletingPartner(null)}
                className="text-sm text-slate"
              >
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmDelete} className="text-sm text-[#B3261E]">
                Remover
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            &ldquo;{deletingPartner.name}&rdquo; será removido permanentemente.
          </p>
        </Modal>
      )}
    </div>
  )
}

function PartnerRow({
  partner,
  onEdit,
  onDelete,
}: {
  partner: Partner
  onEdit: () => void
  onDelete: () => void
}) {
  const subtitle = [partner.contactName, partner.phone, partner.email].filter(Boolean).join('  ·  ')

  return (
    <div className="flex items-center gap-3.5 px-5 py-3.5">
      <div className="min-w-0 flex-1">
        <p className="truncate text-[14.5px] font-bold text-cream">{partner.name}</p>
        {subtitle && <p className="truncate text-xs text-slate">{subtitle}</p>}
      </div>
      <button type="button" aria-label="Editar" onClick={onEdit} className="shrink-0 text-slate">
        ✎
      </button>
      <button type="button" aria-label="Remover" onClick={onDelete} className="shrink-0 text-slate">
        🗑
      </button>
    </div>
  )
}
