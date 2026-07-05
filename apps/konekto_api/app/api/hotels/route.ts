import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

interface HotelConfigShape {
  hotelInfo?: { name?: string }
}

export async function GET() {
  const hotels = await prisma.hotel.findMany({ select: { id: true, config: true } })
  const directory = hotels.map((hotel) => {
    const config = hotel.config as HotelConfigShape
    return { id: hotel.id, name: config.hotelInfo?.name ?? hotel.id }
  })
  return NextResponse.json(directory)
}
