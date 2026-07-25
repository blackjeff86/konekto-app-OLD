/** Portado de apps/konekto_portal/lib/data/coupons_repository.dart. */
import { apiRequest } from './client'
import type { Coupon, CouponInput } from '@/types/coupon'

export function listCoupons(hotelId: string, token: string): Promise<Coupon[]> {
  return apiRequest<Coupon[]>(`/api/hotels/${hotelId}/coupons`, {
    token,
    errorMessage: 'Falha ao carregar cupons.',
  })
}

export function createCoupon(hotelId: string, token: string, input: CouponInput): Promise<Coupon> {
  return apiRequest<Coupon>(`/api/hotels/${hotelId}/coupons`, {
    method: 'POST',
    token,
    body: input,
    conflictMessage: 'Já existe um cupom com esse código.',
    errorMessage: 'Falha ao criar cupom.',
  })
}

export function updateCoupon(
  hotelId: string,
  couponId: string,
  token: string,
  input: CouponInput,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/coupons/${couponId}`, {
    method: 'PATCH',
    token,
    body: input,
    conflictMessage: 'Já existe um cupom com esse código.',
    errorMessage: 'Falha ao atualizar cupom.',
  })
}

export function setCouponEnabled(
  hotelId: string,
  couponId: string,
  token: string,
  enabled: boolean,
): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/coupons/${couponId}`, {
    method: 'PATCH',
    token,
    body: { enabled },
    errorMessage: 'Falha ao atualizar cupom.',
  })
}

export function deleteCoupon(hotelId: string, couponId: string, token: string): Promise<void> {
  return apiRequest<void>(`/api/hotels/${hotelId}/coupons/${couponId}`, {
    method: 'DELETE',
    token,
    conflictMessage: 'Esse cupom já foi usado em pedidos — desative-o em vez de remover.',
    errorMessage: 'Falha ao remover cupom.',
  })
}
