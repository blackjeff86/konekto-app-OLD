import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Lista de gestão do portal — todos os parceiros cadastrados do hotel,
// usados pra vincular a itens do catálogo (ver items/route.ts).
export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

  let staff
  try {
    staff = await requireStaffRole(request, ['gerente', 'recepcao'])
  } catch (error) {
    if (error instanceof AuthGuardError) return error.response
    throw error
  }
  if (staff.hotelId !== hotelId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  const partners = await prisma.partner.findMany({ where: { hotelId }, orderBy: { name: 'asc' } })
  return NextResponse.json(partners)
}

const createPartnerSchema = z.object({
  name: z.string().trim().min(1),
  contactName: z.string().trim().min(1).optional(),
  phone: z.string().trim().min(1).optional(),
  email: z.string().trim().email().optional(),
  notes: z.string().trim().min(1).optional(),
})

// Cadastro de empresa parceira — só `gerente` (configuração estrutural do
// hotel, mesmo padrão de Cupons/Serviços/Quartos).
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

  const parsed = createPartnerSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const partner = await prisma.partner.create({ data: { hotelId, ...parsed.data } })
  return NextResponse.json(partner, { status: 201 })
}
