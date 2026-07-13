import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

// Busca o cadastro mais recente de uma pessoa pelo documento (CPF ou
// passaporte/outro, se estrangeiro) — usado ao ocupar um quarto, pra
// reaproveitar os dados de alguém que já se hospedou antes em vez de
// digitar tudo de novo. 404 quando é realmente um hóspede novo.
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

  const documentNumber = request.nextUrl.searchParams.get('documentNumber')?.trim()
  if (!documentNumber) {
    return NextResponse.json({ error: 'missing_document_number' }, { status: 400 })
  }

  const guest = await prisma.guest.findFirst({
    where: { hotelId, documentNumber },
    orderBy: { createdAt: 'desc' },
  })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  return NextResponse.json({
    firstName: guest.firstName,
    lastName: guest.lastName,
    documentType: guest.documentType,
    documentNumber: guest.documentNumber,
    phoneCountryCode: guest.phoneCountryCode,
    phoneNumber: guest.phoneNumber,
    whatsappCountryCode: guest.whatsappCountryCode,
    whatsappNumber: guest.whatsappNumber,
    email: guest.email,
    address: guest.address,
    country: guest.country,
  })
}
