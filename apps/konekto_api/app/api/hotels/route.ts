import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { enforceRateLimit } from '@/lib/rate-limit'
import { withRequestLogging } from '@/lib/request-logging'

export const runtime = 'nodejs'

interface HotelConfigShape {
  hotelInfo?: { name?: string }
}

export async function GET(request: NextRequest) {
  return withRequestLogging(request, { route: '/api/hotels', surface: 'public-config' }, async () => {
    const rateLimited = enforceRateLimit(request, {
      bucket: 'public-hotels-directory',
      max: 120,
      windowMs: 60 * 1000,
    })
    if (rateLimited) return rateLimited

    const hotels = await prisma.hotel.findMany({ select: { id: true, config: true } })
    const directory = hotels.map((hotel) => {
      const config = hotel.config as HotelConfigShape
      return { id: hotel.id, name: config.hotelInfo?.name ?? hotel.id }
    })
    return NextResponse.json(directory)
  })
}
