import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireGuestAuth, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Cupons que o hóspede autenticado pode ver/escolher — só os ativos e
// dentro da validade do próprio hotel dele (nunca de outro, `hotelId`
// sempre do token verificado). Cada um vem com `eligible`: false quando
// o limite de uso (total ou por hóspede) já foi atingido, pra UI mostrar
// desabilitado em vez de deixar escolher e falhar só na hora do pedido.
export async function GET(request: NextRequest) {
  let guest
  try {
    guest = await requireGuestAuth(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const now = new Date()
  const coupons = await prisma.coupon.findMany({
    where: {
      hotelId: guest.hotelId,
      enabled: true,
      OR: [{ validFrom: null }, { validFrom: { lte: now } }],
      AND: [{ OR: [{ validUntil: null }, { validUntil: { gte: now } }] }],
    },
    orderBy: { position: 'asc' },
  })

  const shaped = await Promise.all(
    coupons.map(async (coupon) => {
      const [totalUses, guestUses] = await Promise.all([
        coupon.usageLimit != null
          ? prisma.order.count({ where: { couponId: coupon.id } })
          : Promise.resolve(0),
        prisma.order.count({ where: { couponId: coupon.id, guestId: guest.sub } }),
      ])
      const eligible = (coupon.usageLimit == null || totalUses < coupon.usageLimit) && guestUses < coupon.perGuestLimit
      return { ...coupon, eligible }
    }),
  )

  return NextResponse.json(shaped)
}
