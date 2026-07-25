/** Portado de apps/konekto_portal/lib/models/coupon.dart. */
export type CouponDiscountType = 'percentage' | 'fixed_amount'

export const couponDiscountTypeLabel: Record<CouponDiscountType, string> = {
  percentage: 'Percentual',
  fixed_amount: 'Valor fixo',
}

export interface Coupon {
  id: string
  title: string
  description: string
  code: string
  discountType: CouponDiscountType
  discountValue: number
  minOrderValue: number | null
  imageUrl: string | null
  validFrom: string | null
  validUntil: string | null
  usageLimit: number | null
  perGuestLimit: number
  enabled: boolean
}

export function couponDiscountLabel(coupon: Pick<Coupon, 'discountType' | 'discountValue'>): string {
  return coupon.discountType === 'percentage'
    ? `${coupon.discountValue.toFixed(0)}%`
    : `R$ ${coupon.discountValue.toFixed(2)}`
}

export function isCouponExpired(coupon: Pick<Coupon, 'validUntil'>): boolean {
  return coupon.validUntil != null && new Date(coupon.validUntil) < new Date()
}

/** Dados do formulário de criação/edição de um cupom. */
export interface CouponInput {
  title: string
  description: string
  code: string
  discountType: CouponDiscountType
  discountValue: number
  minOrderValue?: number | null
  imageUrl?: string | null
  validFrom?: string | null
  validUntil?: string | null
  usageLimit?: number | null
  perGuestLimit: number
  enabled?: boolean
}
