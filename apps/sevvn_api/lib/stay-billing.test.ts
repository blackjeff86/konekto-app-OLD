import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    order: { findMany: vi.fn() },
    stayPayment: { aggregate: vi.fn() },
  },
}))

import { prisma } from '@/lib/prisma'
import { computeStayBill } from './stay-billing'

describe('computeStayBill', () => {
  beforeEach(() => vi.clearAllMocks())

  it('sums order price * quantity and subtracts amounts already paid', async () => {
    vi.mocked(prisma.order.findMany).mockResolvedValue([
      { id: 'o1', itemName: 'Suco', quantity: 2, price: 10, createdAt: new Date('2026-01-01') },
      { id: 'o2', itemName: 'Massagem', quantity: 1, price: 150, createdAt: new Date('2026-01-02') },
    ] as never)
    vi.mocked(prisma.stayPayment.aggregate).mockResolvedValue({ _sum: { amount: 50 } } as never)

    const bill = await computeStayBill('stay_1')

    expect(bill.totalOrders).toBe(170)
    expect(bill.totalPaid).toBe(50)
    expect(bill.balanceDue).toBe(120)
    expect(bill.orders).toHaveLength(2)
  })

  it('never returns a negative balance even if overpaid', async () => {
    vi.mocked(prisma.order.findMany).mockResolvedValue([
      { id: 'o1', itemName: 'Suco', quantity: 1, price: 10, createdAt: new Date() },
    ] as never)
    vi.mocked(prisma.stayPayment.aggregate).mockResolvedValue({ _sum: { amount: 999 } } as never)

    const bill = await computeStayBill('stay_1')

    expect(bill.balanceDue).toBe(0)
  })

  it('scopes the order query to non-cancelled, hotel-payable orders with a price, for the given stay', async () => {
    vi.mocked(prisma.order.findMany).mockResolvedValue([] as never)
    vi.mocked(prisma.stayPayment.aggregate).mockResolvedValue({ _sum: { amount: null } } as never)

    await computeStayBill('stay_42')

    expect(prisma.order.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { guest: { stayId: 'stay_42' }, status: { not: 'cancelled' }, price: { not: null }, paymentMode: 'hotel' },
      }),
    )
  })
})
