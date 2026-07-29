import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from '@/lib/prisma'
import { signPlatformAdminToken } from '@/lib/platform-auth'
import { enforceRateLimit } from '@/lib/rate-limit'
import { withRequestLogging } from '@/lib/request-logging'

export const runtime = 'nodejs'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

// Sem endpoint de auto-cadastro — contas de admin da plataforma são
// criadas via `prisma/seed.ts` (só o time da Sevvn usa isso).
export async function POST(request: NextRequest) {
  return withRequestLogging(request, { route: '/api/platform-admin/login', surface: 'platform-admin-auth' }, async () => {
    const rateLimited = enforceRateLimit(request, {
      bucket: 'platform-admin-login',
      max: 5,
      windowMs: 10 * 60 * 1000,
    })
    if (rateLimited) return rateLimited

    const parsed = loginSchema.safeParse(await request.json().catch(() => null))
    if (!parsed.success) {
      return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
    }

    const { email, password } = parsed.data
    const admin = await prisma.platformAdmin.findUnique({ where: { email } })
    if (!admin || !(await bcrypt.compare(password, admin.passwordHash))) {
      return NextResponse.json({ error: 'invalid_credentials' }, { status: 401 })
    }

    const token = await signPlatformAdminToken({ sub: admin.id, email: admin.email, name: admin.name })

    return NextResponse.json({
      token,
      admin: { id: admin.id, name: admin.name, email: admin.email },
    })
  })
}
