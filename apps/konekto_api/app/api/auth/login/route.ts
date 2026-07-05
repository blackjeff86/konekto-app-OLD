import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'

export const runtime = 'nodejs'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null)
  const parsed = loginSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const { email, password } = parsed.data
  const staff = await prisma.staff.findUnique({ where: { email } })
  if (!staff || !(await bcrypt.compare(password, staff.passwordHash))) {
    return NextResponse.json({ error: 'invalid_credentials' }, { status: 401 })
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
