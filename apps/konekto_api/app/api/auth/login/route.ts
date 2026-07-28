import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from '@/lib/prisma'
import { signStaffToken } from '@/lib/jwt'
import { enforceRateLimit } from '@/lib/rate-limit'
import { withRequestLogging } from '@/lib/request-logging'

export const runtime = 'nodejs'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

export async function POST(request: NextRequest) {
  return withRequestLogging(request, { route: '/api/auth/login', surface: 'staff-auth' }, async () => {
    const rateLimited = enforceRateLimit(request, {
      bucket: 'staff-login',
      max: 10,
      windowMs: 10 * 60 * 1000,
    })
    if (rateLimited) return rateLimited

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
  })
}
