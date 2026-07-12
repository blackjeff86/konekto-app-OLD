import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

interface CustomerStayEntry {
  stayId: string
  roomNumber: string
  checkInDate: Date
  checkOutDate: Date
  status: string
  nights: number
  spent: number
}

interface CustomerAggregate {
  documentType: string
  documentNumber: string
  firstName: string
  lastName: string
  email: string | null
  phoneCountryCode: string
  phoneNumber: string
  whatsappCountryCode: string | null
  whatsappNumber: string | null
  country: string
  stays: CustomerStayEntry[]
}

const MS_PER_NIGHT = 24 * 60 * 60 * 1000

// Não existe uma tabela "Customer" própria — a mesma pessoa gera um `Guest`
// novo a cada estadia (documento é o único jeito de saber que é "a mesma
// pessoa voltando"). Esse endpoint agrega tudo isso na hora, em memória:
// pra escala de um hotel/pousada (dezenas a poucas centenas de hóspedes),
// isso é mais simples e barato que manter uma tabela derivada sincronizada.
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

  const guests = await prisma.guest.findMany({
    where: { hotelId },
    orderBy: { createdAt: 'asc' },
    select: {
      documentType: true,
      documentNumber: true,
      firstName: true,
      lastName: true,
      email: true,
      phoneCountryCode: true,
      phoneNumber: true,
      whatsappCountryCode: true,
      whatsappNumber: true,
      country: true,
      stayId: true,
      stay: { select: { checkInDate: true, checkOutDate: true, status: true, room: { select: { number: true } } } },
      orders: { select: { price: true, quantity: true } },
    },
  })

  const byDocument = new Map<string, CustomerAggregate>()
  for (const guest of guests) {
    const spent = guest.orders.reduce((sum, order) => sum + (order.price ?? 0) * order.quantity, 0)
    const nights = Math.max(
      1,
      Math.round((guest.stay.checkOutDate.getTime() - guest.stay.checkInDate.getTime()) / MS_PER_NIGHT),
    )
    const stayEntry: CustomerStayEntry = {
      stayId: guest.stayId,
      roomNumber: guest.stay.room.number,
      checkInDate: guest.stay.checkInDate,
      checkOutDate: guest.stay.checkOutDate,
      status: guest.stay.status,
      nights,
      spent,
    }

    // Guests vêm ordenados por createdAt asc — o registro mais recente do
    // mesmo documento sempre sobrescreve nome/contato (dado mais atual).
    const existing = byDocument.get(guest.documentNumber)
    if (existing) {
      existing.firstName = guest.firstName
      existing.lastName = guest.lastName
      existing.email = guest.email
      existing.phoneCountryCode = guest.phoneCountryCode
      existing.phoneNumber = guest.phoneNumber
      existing.whatsappCountryCode = guest.whatsappCountryCode
      existing.whatsappNumber = guest.whatsappNumber
      existing.country = guest.country
      existing.stays.push(stayEntry)
    } else {
      byDocument.set(guest.documentNumber, {
        documentType: guest.documentType,
        documentNumber: guest.documentNumber,
        firstName: guest.firstName,
        lastName: guest.lastName,
        email: guest.email,
        phoneCountryCode: guest.phoneCountryCode,
        phoneNumber: guest.phoneNumber,
        whatsappCountryCode: guest.whatsappCountryCode,
        whatsappNumber: guest.whatsappNumber,
        country: guest.country,
        stays: [stayEntry],
      })
    }
  }

  const customers = Array.from(byDocument.values()).map((customer) => {
    const checkInTimes = customer.stays.map((stay) => stay.checkInDate.getTime())
    return {
      ...customer,
      visitsCount: customer.stays.length,
      totalSpent: customer.stays.reduce((sum, stay) => sum + stay.spent, 0),
      firstVisit: new Date(Math.min(...checkInTimes)),
      lastVisit: new Date(Math.max(...checkInTimes)),
    }
  })
  customers.sort((a, b) => b.lastVisit.getTime() - a.lastVisit.getTime())

  return NextResponse.json(customers)
}
