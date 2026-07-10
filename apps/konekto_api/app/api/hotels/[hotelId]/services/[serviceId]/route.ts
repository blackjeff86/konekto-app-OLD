import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { verifyStaffToken } from '@/lib/jwt'

export const runtime = 'nodejs'

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

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params
  const service = await prisma.service.findUnique({
    where: { id: serviceId, hotelId },
    include: { items: { where: { hidden: false }, orderBy: { position: 'asc' } } },
  })
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }
  if (!service.enabled && !(await isGerenteOfHotel(request, hotelId))) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }
  return NextResponse.json(service)
}

const patchServiceSchema = z.object({
  name: z.string().min(1).optional(),
  icon: z.string().min(1).optional(),
  description: z.string().optional(),
  bannerImageUrl: z.string().min(1).nullable().optional(),
  enabled: z.boolean().optional(),
  position: z.number().int().min(0).optional(),
})

async function authorizeGerente(request: NextRequest, hotelId: string): Promise<NextResponse | null> {
  try {
    const staff = await requireStaffRole(request, ['gerente'])
    if (staff.hotelId !== hotelId) {
      return NextResponse.json({ error: 'forbidden' }, { status: 403 })
    }
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  return null
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params

  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const parsed = patchServiceSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const existing = await prisma.service.findUnique({ where: { id: serviceId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  const updated = await prisma.service.update({
    where: { id: serviceId },
    data: parsed.data,
  })
  return NextResponse.json(updated)
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params

  const authError = await authorizeGerente(request, hotelId)
  if (authError) return authError

  const existing = await prisma.service.findUnique({ where: { id: serviceId, hotelId } })
  if (!existing) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  await prisma.service.delete({ where: { id: serviceId } })
  return NextResponse.json({ success: true })
}
