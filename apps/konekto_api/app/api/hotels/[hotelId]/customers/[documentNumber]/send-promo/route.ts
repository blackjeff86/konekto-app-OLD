import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { getResendClient, resendFromAddress } from '@/lib/resend'

export const runtime = 'nodejs'

const sendPromoSchema = z.object({
  couponId: z.string().trim().min(1),
  message: z.string().trim().max(500).optional(),
})

interface HotelConfigShape {
  hotelInfo?: { name?: string }
}

function discountLabel(discountType: string, discountValue: number): string {
  return discountType === 'percentage' ? `${discountValue.toFixed(0)}%` : `R$ ${discountValue.toFixed(2)}`
}

// Manda um e-mail promocional com um cupom existente pra um cliente do
// histórico (não precisa ter estadia ativa agora) — gerente only, já que é
// uma ação de marketing que expõe o e-mail do hóspede a um envio real.
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; documentNumber: string }> },
) {
  const { hotelId, documentNumber } = await params

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

  const parsed = sendPromoSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const coupon = await prisma.coupon.findUnique({ where: { id: parsed.data.couponId } })
  if (!coupon || coupon.hotelId !== hotelId) {
    return NextResponse.json({ error: 'coupon_not_found' }, { status: 404 })
  }

  // Documento identifica "o mesmo cliente" através de várias estadias — o
  // registro mais recente tem o e-mail/nome mais atual, igual à agregação
  // feita em GET /customers.
  const guest = await prisma.guest.findFirst({
    where: { hotelId, documentNumber },
    orderBy: { createdAt: 'desc' },
    select: { firstName: true, lastName: true, email: true },
  })
  if (!guest) {
    return NextResponse.json({ error: 'customer_not_found' }, { status: 404 })
  }
  if (!guest.email) {
    return NextResponse.json({ error: 'customer_no_email' }, { status: 400 })
  }

  const hotel = await prisma.hotel.findUnique({ where: { id: hotelId } })
  const hotelName = (hotel?.config as HotelConfigShape | undefined)?.hotelInfo?.name ?? hotelId

  const html = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <p>Olá, ${guest.firstName}!</p>
      <p>${hotelName} preparou uma oferta especial pra você:</p>
      <div style="border: 1px solid #e0e0e0; border-radius: 12px; padding: 16px; margin: 16px 0;">
        <h2 style="margin: 0 0 8px;">${coupon.title}</h2>
        <p style="margin: 0 0 8px; color: #555;">${coupon.description}</p>
        <p style="margin: 0; font-weight: bold; font-size: 18px;">${discountLabel(coupon.discountType, coupon.discountValue)} de desconto</p>
      </div>
      ${parsed.data.message ? `<p>${parsed.data.message}</p>` : ''}
      <p style="color: #888; font-size: 12px;">Válido na sua próxima estadia, sujeito às condições do cupom.</p>
    </div>
  `

  try {
    const resend = getResendClient()
    const result = await resend.emails.send({
      from: resendFromAddress,
      to: guest.email,
      subject: `${hotelName} tem uma promoção pra você!`,
      html,
    })
    if (result.error) {
      return NextResponse.json({ error: 'send_failed', detail: result.error.message }, { status: 502 })
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown_error'
    return NextResponse.json({ error: 'send_failed', detail: message }, { status: 502 })
  }

  return NextResponse.json({ success: true })
}
