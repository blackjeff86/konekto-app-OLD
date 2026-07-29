import { NextRequest } from 'next/server'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const tx = {
  $executeRaw: vi.fn(),
  hotelPaymentAccount: { findUnique: vi.fn() },
  stayPayment: { create: vi.fn(), update: vi.fn() },
}

vi.mock('@/lib/prisma', () => ({
  prisma: {
    guest: { findUnique: vi.fn() },
    $transaction: vi.fn(async (callback: (tx: unknown) => unknown) => callback(tx)),
  },
}))

vi.mock('@/lib/stay-billing', () => ({
  computeStayBill: vi.fn(),
}))

vi.mock('@/lib/pagarme', () => ({
  createOrderWithSplit: vi.fn(),
  PagarmeError: class PagarmeError extends Error {
    constructor(
      public status: number,
      public body: unknown,
    ) {
      super('PagarmeError')
    }
  },
}))

vi.mock('@/lib/stay-expiration', () => ({
  expireStay: vi.fn(),
}))

import { prisma } from '@/lib/prisma'
import { computeStayBill } from '@/lib/stay-billing'
import { createOrderWithSplit } from '@/lib/pagarme'
import { signGuestToken } from '@/lib/guest-auth'
import { POST } from './route'

function payRequest(token: string | null, body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/guest/stay-bill/pay', {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  })
}

const guestPayload = { sub: 'guest_1', hotelId: 'hotel_1', firstName: 'Jefferson', lastName: 'Brito', roomNumber: '701' }

describe('POST /api/guest/stay-bill/pay', () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    vi.clearAllMocks()
    process.env.PAGARME_MASTER_RECIPIENT_ID = 'rp_platform'
    process.env.PAGARME_PLATFORM_FEE_PERCENT = '5'
    vi.mocked(prisma.guest.findUnique).mockResolvedValue({
      id: 'guest_1',
      stayId: 'stay_1',
      hotelId: 'hotel_1',
      firstName: 'Jefferson',
      lastName: 'Brito',
      documentNumber: '12345678900',
      status: 'active',
      stay: { status: 'active', checkOutDate: new Date(Date.now() + 86400000) },
    } as never)
  })

  afterEach(() => {
    process.env = { ...originalEnv }
  })

  it('rejects when PAGARME_MASTER_RECIPIENT_ID is not configured, without touching the database', async () => {
    delete process.env.PAGARME_MASTER_RECIPIENT_ID
    const token = await signGuestToken(guestPayload);

    const response = await POST(payRequest(token, { cardToken: 'tok_1' }))

    expect(response.status).toBe(503)
    expect(prisma.$transaction).not.toHaveBeenCalled()
  })

  it('rejects when the hotel has no verified payment account', async () => {
    const token = await signGuestToken(guestPayload)
    tx.hotelPaymentAccount.findUnique.mockResolvedValue(null)

    const response = await POST(payRequest(token, { cardToken: 'tok_1' }))

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBe('hotel_not_configured_for_payments')
  })

  it('rejects when there is nothing to pay', async () => {
    const token = await signGuestToken(guestPayload)
    tx.hotelPaymentAccount.findUnique.mockResolvedValue({ hotelId: 'hotel_1', pagarmeRecipientId: 'rp_hotel', status: 'verified' });
    vi.mocked(computeStayBill).mockResolvedValue({ orders: [], totalOrders: 0, totalPaid: 0, balanceDue: 0 })

    const response = await POST(payRequest(token, { cardToken: 'tok_1' }))

    expect(response.status).toBe(400)
    const body = await response.json()
    expect(body.error).toBe('nothing_to_pay')
  })

  it('acquires a per-stay advisory lock before computing the balance', async () => {
    const token = await signGuestToken(guestPayload)
    tx.hotelPaymentAccount.findUnique.mockResolvedValue({ hotelId: 'hotel_1', pagarmeRecipientId: 'rp_hotel', status: 'verified' });
    vi.mocked(computeStayBill).mockResolvedValue({ orders: [], totalOrders: 0, totalPaid: 0, balanceDue: 0 })

    await POST(payRequest(token, { cardToken: 'tok_1' }))

    expect(tx.$executeRaw).toHaveBeenCalled()
  })

  it('creates a paid StayPayment and splits between platform and hotel recipients', async () => {
    const token = await signGuestToken(guestPayload)
    tx.hotelPaymentAccount.findUnique.mockResolvedValue({ hotelId: 'hotel_1', pagarmeRecipientId: 'rp_hotel', status: 'verified' });
    vi.mocked(computeStayBill).mockResolvedValue({ orders: [], totalOrders: 150, totalPaid: 0, balanceDue: 150 })
    tx.stayPayment.create.mockResolvedValue({ id: 'sp_1' });
    vi.mocked(createOrderWithSplit).mockResolvedValue({
      orderId: 'order_1',
      orderStatus: 'paid',
      chargeId: 'charge_1',
      chargeStatus: 'paid',
    })
    tx.stayPayment.update.mockResolvedValue({ id: 'sp_1', status: 'paid', amount: 150 });

    const response = await POST(payRequest(token, { cardToken: 'tok_1' }))

    expect(response.status).toBe(200)
    const [splitCall] = vi.mocked(createOrderWithSplit).mock.calls
    expect(splitCall[0].split).toEqual([
      { recipientId: 'rp_platform', percentage: 5, liable: true, chargeProcessingFee: true, chargeRemainderFee: false },
      { recipientId: 'rp_hotel', percentage: 95, liable: false, chargeProcessingFee: false, chargeRemainderFee: true },
    ])
    expect(tx.stayPayment.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ status: 'paid' }) }))
  })

  it('marks the StayPayment as failed and never echoes the raw Pagar.me error to the client', async () => {
    const token = await signGuestToken(guestPayload)
    tx.hotelPaymentAccount.findUnique.mockResolvedValue({ hotelId: 'hotel_1', pagarmeRecipientId: 'rp_hotel', status: 'verified' });
    vi.mocked(computeStayBill).mockResolvedValue({ orders: [], totalOrders: 150, totalPaid: 0, balanceDue: 150 })
    tx.stayPayment.create.mockResolvedValue({ id: 'sp_1' });
    const { PagarmeError } = await import('@/lib/pagarme')
    vi.mocked(createOrderWithSplit).mockRejectedValue(new PagarmeError(422, { message: 'super secret gateway diagnostic' }))
    tx.stayPayment.update.mockResolvedValue({ id: 'sp_1', status: 'failed' });

    const response = await POST(payRequest(token, { cardToken: 'tok_1' }))

    expect(response.status).toBe(402)
    const body = await response.json()
    expect(body.error).toBe('payment_failed')
    expect(JSON.stringify(body)).not.toContain('super secret gateway diagnostic')
    expect(tx.stayPayment.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ status: 'failed' }) }))
  })
})
