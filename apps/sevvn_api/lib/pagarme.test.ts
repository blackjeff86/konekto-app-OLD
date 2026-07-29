import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createOrderWithSplit, getRecipient, PagarmeError } from './pagarme'

function jsonResponse(status: number, body: unknown) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
  } as Response
}

describe('pagarme client', () => {
  const originalKey = process.env.PAGARME_API_KEY
  const originalFetch = global.fetch

  beforeEach(() => {
    process.env.PAGARME_API_KEY = 'sk_test_123'
    global.fetch = vi.fn()
  })

  afterEach(() => {
    process.env.PAGARME_API_KEY = originalKey
    global.fetch = originalFetch
  })

  describe('getRecipient', () => {
    it('sends HTTP Basic auth with the secret key and empty password', async () => {
      vi.mocked(global.fetch).mockResolvedValue(jsonResponse(200, { id: 'rp_1', status: 'active' }))

      await getRecipient('rp_1')

      const [url, init] = vi.mocked(global.fetch).mock.calls[0];
      expect(url).toBe('https://api.pagar.me/core/v5/recipients/rp_1')
      const expectedAuth = `Basic ${Buffer.from('sk_test_123:').toString('base64')}`
      expect((init?.headers as Record<string, string>).Authorization).toBe(expectedAuth)
    })

    it('returns the recipient id and status', async () => {
      vi.mocked(global.fetch).mockResolvedValue(jsonResponse(200, { id: 'rp_1', status: 'active' }))

      const result = await getRecipient('rp_1')

      expect(result).toEqual({ id: 'rp_1', status: 'active' })
    })

    it('throws PagarmeError with the status and body when the request fails', async () => {
      vi.mocked(global.fetch).mockResolvedValue(jsonResponse(404, { message: 'recipient not found' }))

      await expect(getRecipient('rp_missing')).rejects.toThrow(PagarmeError)
    })

    it('throws when PAGARME_API_KEY is missing', async () => {
      delete process.env.PAGARME_API_KEY

      await expect(getRecipient('rp_1')).rejects.toThrow('PAGARME_API_KEY')
      expect(global.fetch).not.toHaveBeenCalled()
    })
  })

  describe('createOrderWithSplit', () => {
    const baseInput = {
      code: 'stay_payment_1',
      amountInCents: 15000,
      cardToken: 'tok_abc',
      customerName: 'Jefferson Brito',
      customerDocument: '12345678900',
      split: [
        { recipientId: 'rp_platform', percentage: 5, liable: true, chargeProcessingFee: true, chargeRemainderFee: false },
        { recipientId: 'rp_hotel', percentage: 95, liable: false, chargeProcessingFee: false, chargeRemainderFee: true },
      ],
    }

    it('sends split as a top-level field of the order body', async () => {
      vi.mocked(global.fetch).mockResolvedValue(
        jsonResponse(200, { id: 'order_1', status: 'paid', charges: [{ id: 'charge_1', status: 'paid' }] }),
      )

      await createOrderWithSplit(baseInput)

      const [, init] = vi.mocked(global.fetch).mock.calls[0]
      const body = JSON.parse(init?.body as string)
      expect(body.split).toEqual([
        {
          recipient_id: 'rp_platform',
          type: 'percentage',
          amount: 5,
          options: { liable: true, charge_processing_fee: true, charge_remainder_fee: false },
        },
        {
          recipient_id: 'rp_hotel',
          type: 'percentage',
          amount: 95,
          options: { liable: false, charge_processing_fee: false, charge_remainder_fee: true },
        },
      ])
      expect(body.payments).toEqual([{ payment_method: 'credit_card', credit_card: { card_token: 'tok_abc' } }])
    })

    it('extracts the order id/status and first charge id/status from the response', async () => {
      vi.mocked(global.fetch).mockResolvedValue(
        jsonResponse(200, { id: 'order_1', status: 'paid', charges: [{ id: 'charge_1', status: 'paid' }] }),
      )

      const result = await createOrderWithSplit(baseInput)

      expect(result).toEqual({ orderId: 'order_1', orderStatus: 'paid', chargeId: 'charge_1', chargeStatus: 'paid' })
    })

    it('throws PagarmeError when the card is declined', async () => {
      vi.mocked(global.fetch).mockResolvedValue(jsonResponse(422, { message: 'card declined' }))

      await expect(createOrderWithSplit(baseInput)).rejects.toThrow(PagarmeError)
    })
  })
})
