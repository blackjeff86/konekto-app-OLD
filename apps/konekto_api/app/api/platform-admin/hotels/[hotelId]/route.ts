import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'
import { buildHotelOverview } from '@/lib/platform-admin-hotel-shape'

export const runtime = 'nodejs'

// Detalhamento de um hotel cliente — tudo que a lista já tem, mais a
// equipe (staff) com acesso admin ao portal daquele hotel.
export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const [overview, staff] = await Promise.all([
    buildHotelOverview(hotel),
    prisma.staff.findMany({
      where: { hotelId },
      select: { id: true, name: true, email: true, role: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    }),
  ])

  return NextResponse.json({ ...overview, staff })
}
