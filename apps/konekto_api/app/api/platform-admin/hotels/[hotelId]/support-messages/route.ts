import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const messages = await prisma.platformSupportMessage.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'asc' },
  })
  return NextResponse.json(messages)
}

const replySchema = z.object({ message: z.string().trim().min(1).max(2000) })

export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  const parsed = replySchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  if (!hotel) {
    return NextResponse.json({ error: 'hotel_not_found' }, { status: 404 })
  }

  const message = await prisma.platformSupportMessage.create({
    data: {
      hotelId,
      senderType: 'platform',
      body: parsed.data.message,
      readByPlatform: true,
      readByHotel: false,
    },
  })
  return NextResponse.json(message, { status: 201 })
}
