import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import type { Prisma } from '@/app/generated/prisma/client'

export const runtime = 'nodejs'

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; docName: string }> },
) {
  const { hotelId, docName } = await params
  const content = await prisma.hotelContent.findUnique({
    where: { hotelId_docName: { hotelId, docName } },
  })
  if (!content) {
    return NextResponse.json({ error: 'content_not_found' }, { status: 404 })
  }
  return NextResponse.json(content.data)
}

// Substitui o documento inteiro em vez de aceitar um patch parcial — cada
// catálogo (room service, spa, restaurantes, eventos, passeios) tem um
// formato diferente, então a validação estrutural fica no lado do Flutter
// (cada tela conhece o formato do seu próprio catálogo); a API só garante
// que é um objeto JSON e que quem chama é gerente daquele hotel.
const patchContentSchema = z.object({
  data: z.record(z.string(), z.unknown()),
})

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; docName: string }> },
) {
  const { hotelId, docName } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const parsed = patchContentSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  // Upsert em vez de exigir que o doc já exista — o portal agora escreve
  // aqui direto (ex: `guestInfo` pra configurar o wifi padrão do hotel),
  // e nem todo hotel tem cada doc semeado de antemão.
  const updated = await prisma.hotelContent.upsert({
    where: { hotelId_docName: { hotelId, docName } },
    create: { hotelId, docName, data: parsed.data.data as unknown as Prisma.InputJsonValue },
    update: { data: parsed.data.data as unknown as Prisma.InputJsonValue },
  })
  return NextResponse.json(updated.data)
}
