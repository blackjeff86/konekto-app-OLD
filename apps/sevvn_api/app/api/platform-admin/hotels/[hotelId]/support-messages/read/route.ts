import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requirePlatformAdmin, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Marca como lidas (pela plataforma) as mensagens que o hotel mandou —
// chamado quando o admin abre a thread daquele hotel no konekto_admin.
export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  try {
    await requirePlatformAdmin(request)
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }

  await prisma.platformSupportMessage.updateMany({
    where: { hotelId, senderType: 'hotel', readByPlatform: false },
    data: { readByPlatform: true },
  })
  return NextResponse.json({ success: true })
}
