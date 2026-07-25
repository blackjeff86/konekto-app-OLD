import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({
  prisma: {
    stay: { update: vi.fn(), updateMany: vi.fn(), findMany: vi.fn() },
    guest: { updateMany: vi.fn() },
    $transaction: vi.fn((operations: unknown[]) => Promise.all(operations)),
  },
}))

import { prisma } from '@/lib/prisma'
import { expireStay, sweepExpiredStays } from './stay-expiration'

describe('expireStay', () => {
  beforeEach(() => vi.clearAllMocks())

  it('closes the stay and revokes all its guests transactionally', async () => {
    await expireStay('stay_1')

    expect(prisma.stay.update).toHaveBeenCalledWith({ where: { id: 'stay_1' }, data: { status: 'closed' } })
    expect(prisma.guest.updateMany).toHaveBeenCalledWith({ where: { stayId: 'stay_1' }, data: { status: 'revoked' } })
    expect(prisma.$transaction).toHaveBeenCalled()
  })
})

describe('sweepExpiredStays', () => {
  beforeEach(() => vi.clearAllMocks())

  it('does nothing when there are no overdue stays', async () => {
    vi.mocked(prisma.stay.findMany).mockResolvedValue([])

    await sweepExpiredStays('hotel_1')

    expect(prisma.stay.updateMany).not.toHaveBeenCalled()
    expect(prisma.guest.updateMany).not.toHaveBeenCalled()
  })

  it('queries only active stays with a checkOutDate in the past, scoped to the hotel', async () => {
    vi.mocked(prisma.stay.findMany).mockResolvedValue([])

    await sweepExpiredStays('hotel_1')

    expect(prisma.stay.findMany).toHaveBeenCalledWith({
      where: { hotelId: 'hotel_1', status: 'active', checkOutDate: { lt: expect.any(Date) } },
      select: { id: true },
    })
  })

  it('closes every overdue stay and revokes their guests in bulk', async () => {
    vi.mocked(prisma.stay.findMany).mockResolvedValue([{ id: 'stay_1' }, { id: 'stay_2' }] as never)

    await sweepExpiredStays('hotel_1')

    expect(prisma.stay.updateMany).toHaveBeenCalledWith({
      where: { id: { in: ['stay_1', 'stay_2'] } },
      data: { status: 'closed' },
    })
    expect(prisma.guest.updateMany).toHaveBeenCalledWith({
      where: { stayId: { in: ['stay_1', 'stay_2'] } },
      data: { status: 'revoked' },
    })
  })
})
