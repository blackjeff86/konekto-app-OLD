'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { useCustomers } from '@/hooks/useCustomers'
import { useCoupons } from '@/hooks/useCoupons'
import { customerFullName } from '@/types/customer'
import { documentTypeLabel } from '@/types/guest'
import { couponDiscountLabel } from '@/types/coupon'
import { formatDate } from '@/lib/utils/date'

function currency(value: number): string {
  return `R$ ${value.toFixed(2)}`
}

/** Portado de _CustomerDetail (apps/konekto_portal/lib/features/customers/customers_page.dart). */
export default function CustomerDetailPage({
  params,
}: {
  params: Promise<{ documentNumber: string }>
}) {
  const { documentNumber } = use(params)
  const { customers, isLoading, sendPromo } = useCustomers()
  const { coupons, isLoading: couponsLoading } = useCoupons()
  const [selectedCouponIdOverride, setSelectedCouponIdOverride] = useState<string | null>(null)
  const [message, setMessage] = useState('')
  const [isSending, setIsSending] = useState(false)
  const [feedback, setFeedback] = useState<{ text: string; isError: boolean } | null>(null)

  const customer = customers.find((c) => c.documentNumber === documentNumber)
  const enabledCoupons = coupons.filter((coupon) => coupon.enabled)
  const selectedCouponId = selectedCouponIdOverride ?? enabledCoupons[0]?.id ?? null

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  if (!customer) {
    return <p className="text-[13.5px] text-cream">Cliente não encontrado.</p>
  }

  async function handleSendPromo() {
    if (!selectedCouponId || !customer) return
    setIsSending(true)
    setFeedback(null)
    try {
      await sendPromo({ documentNumber: customer.documentNumber, couponId: selectedCouponId, message: message.trim() })
      setFeedback({ text: `E-mail enviado pra ${customer.email}.`, isError: false })
      setMessage('')
    } catch (error) {
      setFeedback({
        text: error instanceof Error ? error.message : 'Falha ao enviar e-mail.',
        isError: true,
      })
    } finally {
      setIsSending(false)
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-2">
        <Link href="/customers" aria-label="Voltar" className="text-slate">
          ←
        </Link>
        <h1 className="flex-1 text-lg font-bold text-cream">{customerFullName(customer)}</h1>
      </div>

      <div className="rounded-2xl border border-border-strong bg-surface p-4.5">
        <h2 className="mb-3 text-[15px] font-bold text-cream">Contato</h2>
        <InfoRow label="Documento" value={`${documentTypeLabel[customer.documentType]} · ${customer.documentNumber}`} />
        <InfoRow label="Telefone" value={`${customer.phoneCountryCode} ${customer.phoneNumber}`} />
        {customer.whatsappNumber && (
          <InfoRow label="WhatsApp" value={`${customer.whatsappCountryCode} ${customer.whatsappNumber}`} />
        )}
        {customer.email && <InfoRow label="E-mail" value={customer.email} />}
        <InfoRow label="País" value={customer.country} />
      </div>

      <div className="grid grid-cols-4 gap-3">
        <StatCard label="Visitas" value={String(customer.visitsCount)} />
        <StatCard label="Total gasto" value={currency(customer.totalSpent)} />
        <StatCard label="Primeira visita" value={formatDate(customer.firstVisit)} />
        <StatCard label="Última visita" value={formatDate(customer.lastVisit)} />
      </div>

      <h2 className="text-[15px] font-bold text-cream">Histórico de estadias</h2>
      <div className="divide-y divide-border-strong rounded-2xl border border-border-strong bg-surface">
        {customer.stays.map((stay) => (
          <div key={stay.stayId} className="flex items-center gap-3.5 px-5 py-3.5">
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-cream">Quarto {stay.roomNumber}</p>
              <p className="text-xs text-slate">
                {formatDate(stay.checkInDate)} – {formatDate(stay.checkOutDate)}  ·  {stay.nights}{' '}
                noite{stay.nights === 1 ? '' : 's'}
              </p>
            </div>
            <span
              className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-semibold ${
                stay.status === 'active' ? 'bg-gold/12 text-gold-light' : 'bg-black/5 text-slate-soft'
              }`}
            >
              {stay.status === 'active' ? 'Ativa' : 'Fechada'}
            </span>
            <span className="shrink-0 text-[13px] font-semibold text-gold-light">
              {currency(stay.spent)}
            </span>
          </div>
        ))}
      </div>

      <h2 className="text-[15px] font-bold text-cream">Enviar promoção</h2>
      <div className="rounded-2xl border border-border-strong bg-surface p-4.5">
        {!customer.email ? (
          <p className="text-[12.5px] text-slate">
            Esse cliente não tem e-mail cadastrado — não é possível enviar promoções.
          </p>
        ) : couponsLoading ? (
          <div className="flex justify-center py-4">
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-gold border-t-transparent" />
          </div>
        ) : enabledCoupons.length === 0 ? (
          <p className="text-[12.5px] text-slate">
            Nenhum cupom ativo no momento — crie um em Configurações &gt; Cupons.
          </p>
        ) : (
          <div className="flex flex-col gap-3">
            <p className="text-[12.5px] text-cream">Manda um e-mail pra {customer.email} com o cupom escolhido.</p>
            <select
              value={selectedCouponId ?? ''}
              onChange={(event) => setSelectedCouponIdOverride(event.target.value)}
              className="rounded-[10px] border border-border-strong bg-surface px-3 py-2.5 text-[13.5px] text-cream outline-none focus:border-gold"
            >
              {enabledCoupons.map((coupon) => (
                <option key={coupon.id} value={coupon.id}>
                  {coupon.title} · {couponDiscountLabel(coupon)}
                </option>
              ))}
            </select>
            <textarea
              value={message}
              onChange={(event) => setMessage(event.target.value)}
              placeholder="Mensagem adicional (opcional)"
              rows={3}
              className="rounded-[10px] border border-border-strong bg-transparent px-3 py-2.5 text-[13.5px] text-cream outline-none focus:border-gold"
            />
            {feedback && (
              <div
                className={`rounded-[10px] border px-3 py-2.5 text-[12.5px] ${
                  feedback.isError
                    ? 'border-[#DC262680] bg-[#DC26261A] text-[#B3261E]'
                    : 'border-[#5CB85C80] bg-[#5CB85C1A] text-[#9FDE9F]'
                }`}
              >
                {feedback.text}
              </div>
            )}
            <button
              type="button"
              onClick={handleSendPromo}
              disabled={isSending || !selectedCouponId}
              className="w-full rounded-full bg-gold py-2.5 text-[13.5px] font-bold text-ink disabled:opacity-60"
            >
              {isSending ? 'Enviando...' : 'Enviar e-mail'}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start gap-2 py-1">
      <span className="w-24 shrink-0 text-[12.5px] text-slate">{label}</span>
      <span className="text-[13.5px] text-cream">{value}</span>
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[14px] border border-border-strong bg-surface p-3.5">
      <p className="text-[11px] text-slate">{label}</p>
      <p className="mt-1 text-[15px] font-bold text-cream">{value}</p>
    </div>
  )
}
