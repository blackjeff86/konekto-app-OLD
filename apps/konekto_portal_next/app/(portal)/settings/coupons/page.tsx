'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { CouponFormDialog } from '@/components/settings/CouponFormDialog'
import { useCoupons } from '@/hooks/useCoupons'
import { couponDiscountLabel, isCouponExpired, type Coupon } from '@/types/coupon'
import { formatDate } from '@/lib/utils/date'

/** Portado de apps/konekto_portal/lib/features/settings/coupons_page.dart. */
export default function CouponsPage() {
  const { coupons, isLoading, error, createCoupon, updateCoupon, setCouponEnabled, deleteCoupon } =
    useCoupons()
  const [editingCoupon, setEditingCoupon] = useState<Coupon | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [deletingCoupon, setDeletingCoupon] = useState<Coupon | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const isDialogOpen = isCreating || editingCoupon !== null

  async function handleSubmit(input: Parameters<typeof createCoupon>[0]) {
    if (editingCoupon) {
      await updateCoupon({ couponId: editingCoupon.id, input })
    } else {
      await createCoupon(input)
    }
    setIsCreating(false)
    setEditingCoupon(null)
  }

  async function handleToggleEnabled(coupon: Coupon) {
    setActionError(null)
    try {
      await setCouponEnabled({ couponId: coupon.id, enabled: !coupon.enabled })
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao atualizar cupom.')
    }
  }

  async function handleConfirmDelete() {
    if (!deletingCoupon) return
    setActionError(null)
    try {
      await deleteCoupon(deletingCoupon.id)
      setDeletingCoupon(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao remover cupom.')
      setDeletingCoupon(null)
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
        <h1 className="text-lg font-bold text-cream">Cupons e promoções</h1>
        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="text-[12.5px] font-semibold text-gold-light"
        >
          + Criar cupom
        </button>
      </div>
      <p className="text-[12.5px] text-slate">
        O hóspede escolhe da lista de cupons elegíveis direto ao fazer um pedido no app — não
        precisa digitar código.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {coupons.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
          Nenhum cupom cadastrado ainda.
        </div>
      ) : (
        <div className="divide-y divide-border-strong rounded-2xl border border-border-strong bg-surface">
          {coupons.map((coupon) => (
            <CouponRow
              key={coupon.id}
              coupon={coupon}
              onEdit={() => setEditingCoupon(coupon)}
              onToggleEnabled={() => handleToggleEnabled(coupon)}
              onDelete={() => setDeletingCoupon(coupon)}
            />
          ))}
        </div>
      )}

      {isDialogOpen && (
        <CouponFormDialog
          existing={editingCoupon}
          onClose={() => {
            setIsCreating(false)
            setEditingCoupon(null)
          }}
          onSubmit={handleSubmit}
        />
      )}

      {deletingCoupon && (
        <Modal
          title="Remover cupom?"
          onClose={() => setDeletingCoupon(null)}
          footer={
            <>
              <button
                type="button"
                onClick={() => setDeletingCoupon(null)}
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
            &ldquo;{deletingCoupon.title}&rdquo; será removido permanentemente.
          </p>
        </Modal>
      )}
    </div>
  )
}

function CouponRow({
  coupon,
  onEdit,
  onToggleEnabled,
  onDelete,
}: {
  coupon: Coupon
  onEdit: () => void
  onToggleEnabled: () => void
  onDelete: () => void
}) {
  const isLive = coupon.enabled && !isCouponExpired(coupon)
  const details = [
    `código ${coupon.code}`,
    coupon.validUntil ? `válido até ${formatDate(coupon.validUntil)}` : null,
    coupon.minOrderValue != null ? `mín. R$ ${coupon.minOrderValue.toFixed(2)}` : null,
  ]
    .filter(Boolean)
    .join('  ·  ')

  return (
    <div className="flex items-center gap-3.5 px-5 py-3.5">
      <span className="shrink-0 rounded-[10px] bg-gold/12 px-2.5 py-1.5 text-[13px] font-bold text-gold-light">
        -{couponDiscountLabel(coupon)}
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[14.5px] font-bold text-cream">{coupon.title}</p>
        <p className="truncate text-xs text-slate">{details}</p>
      </div>
      <span
        className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-semibold ${
          isLive ? 'bg-gold/12 text-gold-light' : 'bg-black/5 text-slate-soft'
        }`}
      >
        {isCouponExpired(coupon) ? 'Expirado' : coupon.enabled ? 'Ativo' : 'Desativado'}
      </span>
      <button
        type="button"
        role="switch"
        aria-checked={coupon.enabled}
        aria-label={`Ativar ou desativar ${coupon.title}`}
        onClick={onToggleEnabled}
        className={`h-5 w-9 shrink-0 rounded-full transition-colors ${
          coupon.enabled ? 'bg-gold' : 'bg-black/15'
        }`}
      >
        <span
          className={`block h-4 w-4 translate-x-0.5 rounded-full bg-white transition-transform ${
            coupon.enabled ? 'translate-x-4.5' : ''
          }`}
        />
      </button>
      <button type="button" aria-label="Editar" onClick={onEdit} className="shrink-0 text-slate">
        ✎
      </button>
      <button type="button" aria-label="Remover" onClick={onDelete} className="shrink-0 text-slate">
        🗑
      </button>
    </div>
  )
}
