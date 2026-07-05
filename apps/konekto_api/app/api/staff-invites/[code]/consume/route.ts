import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'

export const runtime = 'nodejs'

const consumeSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  password: z.string().min(8),
})

export async function POST(request: NextRequest, { params }: { params: Promise<{ code: string }> }) {
  const { code } = await params

  const parsed = consumeSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const invite = await prisma.staffInvite.findUnique({ where: { code } })
  if (!invite) {
    return NextResponse.json({ error: 'invite_not_found' }, { status: 404 })
  }
  if (invite.consumed) {
    return NextResponse.json({ error: 'invite_already_used' }, { status: 409 })
  }

  const existingStaff = await prisma.staff.findUnique({ where: { email: parsed.data.email } })
  if (existingStaff) {
    return NextResponse.json({ error: 'email_already_registered' }, { status: 409 })
  }

  const passwordHash = await bcrypt.hash(parsed.data.password, 10)

  let staff
  try {
    // Reivindica o convite com um `updateMany` condicionado a
    // `consumed: false` dentro da transação: se duas requisições
    // concorrentes chegarem com o mesmo código, só uma vai casar com o
    // WHERE e ter count === 1 — a outra falha aqui, antes de criar staff.
    staff = await prisma.$transaction(async (tx) => {
      const claim = await tx.staffInvite.updateMany({
        where: { code, consumed: false },
        data: { consumed: true },
      })
      if (claim.count !== 1) {
        throw new Error('invite_already_used')
      }
      return tx.staff.create({
        data: {
          hotelId: invite.hotelId,
          role: invite.role,
          name: parsed.data.name,
          email: parsed.data.email,
          passwordHash,
        },
      })
    })
  } catch {
    return NextResponse.json({ error: 'invite_already_used' }, { status: 409 })
  }

  const token = await signStaffToken({
    sub: staff.id,
    hotelId: staff.hotelId,
    role: staff.role,
    email: staff.email,
    name: staff.name,
  })

  return NextResponse.json({
    token,
    staff: { id: staff.id, hotelId: staff.hotelId, role: staff.role, name: staff.name, email: staff.email },
  })
}
