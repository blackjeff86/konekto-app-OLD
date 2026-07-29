import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

interface HotelConfigShape {
  hotelInfo?: { name?: string }
  [key: string]: unknown
}

// Inbox de suporte cross-hotel — só hotéis que já têm pelo menos uma
// mensagem, uma linha por hotel com a mais recente, ordenado por
// atividade. `distinct` + `orderBy` nessa combinação já devolve a última
// mensagem de cada hotelId (padrão documentado do Prisma pra "mais recente
// por grupo"), sem precisar de groupBy.
export async function GET(request: NextRequest) {
  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const latestPerHotel = await prisma.platformSupportMessage.findMany({
    distinct: ['hotelId'],
    orderBy: { createdAt: 'desc' },
  })

  const hotelIds = latestPerHotel.map((message) => message.hotelId)
  const [hotels, unreadCounts] = await Promise.all([
    prisma.hotel.findMany({ where: { id: { in: hotelIds } } }),
    Promise.all(
      hotelIds.map((hotelId) =>
        prisma.platformSupportMessage.count({ where: { hotelId, senderType: 'hotel', readByPlatform: false } }),
      ),
    ),
  ])
  const hotelNameById = new Map(
    hotels.map((hotel) => [hotel.id, (hotel.config as HotelConfigShape).hotelInfo?.name ?? hotel.id]),
  )

  const threads = latestPerHotel.map((message, index) => ({
    hotelId: message.hotelId,
    hotelName: hotelNameById.get(message.hotelId) ?? message.hotelId,
    lastMessageAt: message.createdAt,
    lastMessageBody: message.body,
    lastMessageSenderType: message.senderType,
    unreadByPlatform: unreadCounts[index],
  }))

  return NextResponse.json(threads)
}
