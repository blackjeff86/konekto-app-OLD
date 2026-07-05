import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { verifyStaffToken } from '@/lib/jwt'

export const runtime = 'nodejs'

// Rota pública (app do hóspede não manda token): por padrão só devolve
// serviços habilitados. Se vier um Bearer token válido de gerente do mesmo
// hotel, também inclui os desabilitados — é assim que o portal consegue
// listar (e reabilitar) um serviço que ele mesmo desligou.
async function isGerenteOfHotel(request: NextRequest, hotelId: string): Promise<boolean> {
  const authHeader = request.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) return false
  try {
    const payload = await verifyStaffToken(token)
    return payload.role === 'gerente' && payload.hotelId === hotelId
  } catch {
    return false
  }
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params
  const includeDisabled = await isGerenteOfHotel(request, hotelId)
  const services = await prisma.service.findMany({
    where: includeDisabled ? { hotelId } : { hotelId, enabled: true },
    orderBy: { position: 'asc' },
  })
  return NextResponse.json(services)
}

const createServiceSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  icon: z.string().min(1),
  description: z.string(),
  bannerImageUrl: z.string().min(1).optional(),
})

export async function POST(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

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

  const parsed = createServiceSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.service.findUnique({
    where: { hotelId_slug: { hotelId, slug: parsed.data.slug } },
  })
  if (existing) {
    return NextResponse.json({ error: 'slug_already_exists' }, { status: 409 })
  }

  const maxPosition = await prisma.service.aggregate({
    where: { hotelId },
    _max: { position: true },
  })
  const nextPosition = (maxPosition._max.position ?? -1) + 1

  const service = await prisma.service.create({
    data: { hotelId, position: nextPosition, ...parsed.data },
  })
  return NextResponse.json(service, { status: 201 })
}
