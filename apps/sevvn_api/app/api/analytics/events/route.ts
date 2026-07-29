import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import type { Prisma } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'
import { verifyGuestToken } from '@/lib/guest-auth'

export const runtime = 'nodejs'

const MAX_EVENTS_PER_REQUEST = 50

const analyticsEventSchema = z.object({
  hotelId: z.string().trim().min(1),
  // Nome do evento de domínio (ex: 'ModuleOpened', 'RoomServiceOrdered') —
  // catálogo vive no lado Flutter (lib/events/event_bus.dart), string livre
  // aqui de propósito: evento novo nunca deve exigir migration.
  type: z.string().trim().min(1).max(100),
  payload: z.record(z.string(), z.unknown()).default({}),
})

const requestSchema = z.object({
  events: z.array(analyticsEventSchema).min(1).max(MAX_EVENTS_PER_REQUEST),
})

/// Analytics Engine — endpoint de ingestão, assinante do Event Bus do app
/// do hóspede (envia em lote). Só grava, sem leitura/dashboard nesta
/// entrega. Não é billing-crítico: token de hóspede inválido/ausente nunca
/// bloqueia a escrita, só grava sem `guestId` (ex: evento antes do claim).
export async function POST(request: NextRequest) {
  const parsed = requestSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  let guestId: string | null = null
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (token) {
    try {
      const payload = await verifyGuestToken(token)
      guestId = payload.sub
    } catch {
      // token inválido/expirado — segue sem guestId, nunca rejeita o lote por isso.
    }
  }

  const hotelIds = [...new Set(parsed.data.events.map((event) => event.hotelId))]
  const validHotels = await prisma.hotel.findMany({ where: { id: { in: hotelIds } }, select: { id: true } })
  const validHotelIds = new Set(validHotels.map((hotel) => hotel.id))

  const rows = parsed.data.events
    .filter((event) => validHotelIds.has(event.hotelId))
    .map((event) => ({
      hotelId: event.hotelId,
      guestId,
      type: event.type,
      payload: event.payload as unknown as Prisma.InputJsonValue,
    }))

  if (rows.length > 0) {
    await prisma.analyticsEvent.createMany({ data: rows })
  }

  return NextResponse.json({ accepted: rows.length, rejected: parsed.data.events.length - rows.length }, { status: 202 })
}
