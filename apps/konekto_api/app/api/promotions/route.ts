import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

export async function GET() {
  const brand = await prisma.brandContent.findUnique({ where: { key: 'promotions' } })
  return NextResponse.json(brand?.data ?? { promotions: [] })
}
