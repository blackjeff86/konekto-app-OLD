import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

export async function GET() {
  await prisma.hotel.count()
  return NextResponse.json({ status: 'ok' })
}
