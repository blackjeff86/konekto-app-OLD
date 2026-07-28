import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { enforceRateLimit } from '@/lib/rate-limit'
import { withRequestLogging } from '@/lib/request-logging'

export const runtime = 'nodejs'

export async function GET(request: NextRequest) {
  return withRequestLogging(request, { route: '/api/promotions', surface: 'public-content' }, async () => {
    const rateLimited = enforceRateLimit(request, {
      bucket: 'public-promotions',
      max: 120,
      windowMs: 60 * 1000,
    })
    if (rateLimited) return rateLimited

    const brand = await prisma.brandContent.findUnique({ where: { key: 'promotions' } })
    return NextResponse.json(brand?.data ?? { promotions: [] })
  })
}
