import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireIntegrationAuth, AuthGuardError } from '@/lib/auth-guard'
import { generateAccessCode } from '@/lib/guest-access-code'

export const runtime = 'nodejs'

// Limites de tamanho em campos livres e no array de hóspedes — defesa em
// profundidade contra uma chave de API válida (mas vazada, ou um
// middleware com bug) mandando payloads gigantes que sobrecarregam o
// banco; mesmo espírito do `note: z.string().max(500)` já usado em
// `app/api/orders/route.ts`.
const guestSchema = z.object({
  externalId: z.string().min(1).max(200),
  firstName: z.string().min(1).max(200),
  lastName: z.string().min(1).max(200),
  documentType: z.enum(['cpf', 'passport', 'other']),
  documentNumber: z.string().min(1).max(50),
  phoneCountryCode: z.string().min(1).max(10),
  phoneNumber: z.string().min(1).max(30),
  whatsappCountryCode: z.string().min(1).max(10).optional(),
  whatsappNumber: z.string().min(1).max(30).optional(),
  email: z.string().email().max(320).optional(),
  address: z.string().min(1).max(500).optional(),
  country: z.string().min(1).max(100),
})

const reservationSchema = z.object({
  roomNumber: z.string().min(1).max(50),
  checkInDate: z.coerce.date(),
  checkOutDate: z.coerce.date(),
  status: z.enum(['active', 'closed']).default('active'),
  guests: z.array(guestSchema).max(20).default([]),
})

// Upsert de uma reserva vinda do PMS/middleware do hotel, identificada pelo
// `externalId` na URL (não pelo id interno do Konekto) — reenviar o mesmo
// `externalId` sempre atualiza a mesma `Stay`, nunca duplica. Os hóspedes
// vêm aninhados no mesmo payload (array `guests`), já que `Guest.stayId` é
// obrigatório no schema atual — não existe hóspede sem estadia.
export async function PUT(request: NextRequest, { params }: { params: Promise<{ externalId: string }> }) {
  const { externalId } = await params

  let hotelId: string
  try {
    ;({ hotelId } = await requireIntegrationAuth(request))
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = reservationSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }
  const { roomNumber, checkInDate, checkOutDate, status, guests } = parsed.data

  // Reflete o quarto informado pelo PMS — cria automaticamente se ainda não
  // existir no cadastro do Konekto, pra não bloquear a sincronização numa
  // etapa manual no portal (o PMS passa a ser a fonte da verdade do
  // quarteiro).
  const room = await prisma.room.upsert({
    where: { hotelId_number: { hotelId, number: roomNumber } },
    create: { hotelId, number: roomNumber },
    update: {},
  })

  const existingStay = await prisma.stay.findUnique({ where: { hotelId_externalId: { hotelId, externalId } } })

  // Só uma estadia ativa por quarto — mesma checagem do PATCH de staff
  // (stays/[stayId]/route.ts). Em conflito devolve 409 pro middleware
  // tratar (ex: reenviar depois que o check-out anterior for sincronizado),
  // nunca sobrescreve silenciosamente.
  if (status === 'active' && (!existingStay || existingStay.roomId !== room.id)) {
    const conflicting = await prisma.stay.findFirst({
      where: {
        hotelId,
        roomId: room.id,
        status: 'active',
        ...(existingStay ? { NOT: { id: existingStay.id } } : {}),
      },
    })
    if (conflicting) {
      return NextResponse.json({ error: 'room_already_occupied' }, { status: 409 })
    }
  }

  const stay = await prisma.stay.upsert({
    where: { hotelId_externalId: { hotelId, externalId } },
    create: { hotelId, externalId, roomId: room.id, checkInDate, checkOutDate, status },
    update: { roomId: room.id, checkInDate, checkOutDate, status },
  })

  const syncedGuests = []
  for (const guestInput of guests) {
    // `accessCode` nunca vem do PMS — é sempre gerado pelo Konekto (é o
    // que o hóspede usa pra logar no app), só gerado uma vez na criação.
    const guest = await prisma.guest.upsert({
      where: { hotelId_externalId: { hotelId, externalId: guestInput.externalId } },
      create: { hotelId, stayId: stay.id, accessCode: generateAccessCode(hotelId), ...guestInput },
      update: {
        stayId: stay.id,
        firstName: guestInput.firstName,
        lastName: guestInput.lastName,
        documentType: guestInput.documentType,
        documentNumber: guestInput.documentNumber,
        phoneCountryCode: guestInput.phoneCountryCode,
        phoneNumber: guestInput.phoneNumber,
        whatsappCountryCode: guestInput.whatsappCountryCode,
        whatsappNumber: guestInput.whatsappNumber,
        email: guestInput.email,
        address: guestInput.address,
        country: guestInput.country,
      },
    })
    syncedGuests.push({ id: guest.id, externalId: guest.externalId, accessCode: guest.accessCode })
  }

  await prisma.hotelIntegration.update({ where: { hotelId }, data: { lastInboundSyncAt: new Date() } })

  return NextResponse.json({
    id: stay.id,
    externalId: stay.externalId,
    roomNumber: room.number,
    status: stay.status,
    guests: syncedGuests,
  })
}
