import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import { notifyRestaurantReservationCancelled } from '@/lib/basic-notifications'
import {
  createRestaurantReservationFromWaitlist,
  ensureRestaurantService,
  getRestaurantServiceOperationsState,
  loadRestaurantOperationsDoc,
  saveRestaurantOperationsDoc,
  setRestaurantServiceOperationsState,
  sortWaitlistEntries,
} from '@/lib/restaurant-operations'

export const runtime = 'nodejs'

const releaseReservationSchema = z.object({
  orderId: z.string().min(1),
  autoPromoteNext: z.boolean().default(true),
})

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string }> },
) {
  const { hotelId, serviceId } = await params

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

  const parsed = releaseReservationSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const service = await ensureRestaurantService(serviceId, hotelId)
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  const order = await prisma.order.findFirst({
    where: { id: parsed.data.orderId, hotelId, serviceId, scheduledFor: { not: null } },
  })
  if (!order) {
    return NextResponse.json({ error: 'order_not_found' }, { status: 404 })
  }
  if (order.status === 'cancelled' || order.status === 'completed') {
    return NextResponse.json({ error: 'order_not_active' }, { status: 409 })
  }

  await prisma.order.update({
    where: { id: order.id },
    data: { status: 'cancelled', statusSeenByGuest: false },
  })
  await notifyRestaurantReservationCancelled({
    hotelId,
    guestId: order.guestId,
    reservationId: order.id,
    scheduledFor: order.scheduledFor,
    reason: 'released',
  })

  if (!parsed.data.autoPromoteNext) {
    return NextResponse.json({ releasedOrderId: order.id, promotedEntry: null })
  }

  const doc = await loadRestaurantOperationsDoc(hotelId)
  const state = getRestaurantServiceOperationsState(doc, serviceId)
  const candidate = sortWaitlistEntries(state.waitlist).find(
    (entry) =>
      entry.status === 'waiting' &&
      entry.scheduledFor === order.scheduledFor?.toISOString() &&
      entry.tableTypeId === order.tableTypeId,
  )

  if (!candidate) {
    return NextResponse.json({ releasedOrderId: order.id, promotedEntry: null })
  }

  const promoted = await createRestaurantReservationFromWaitlist({
    hotelId,
    serviceId,
    guestId: candidate.guestId,
    scheduledFor: new Date(candidate.scheduledFor),
    tableTypeId: candidate.tableTypeId,
    note: candidate.note,
  })

  if (!promoted.ok) {
    return NextResponse.json({ releasedOrderId: order.id, promotedEntry: null, promotionError: promoted.error })
  }

  const updatedWaitlist = state.waitlist.map((entry) =>
    entry.id === candidate.id
      ? {
          ...entry,
          status: 'promoted' as const,
          promotedReservationId: promoted.order.id,
          updatedAt: new Date().toISOString(),
        }
      : entry,
  )
  await saveRestaurantOperationsDoc(
    hotelId,
    setRestaurantServiceOperationsState(doc, serviceId, { waitlist: updatedWaitlist }),
  )

  return NextResponse.json({
    releasedOrderId: order.id,
    promotedEntry: updatedWaitlist.find((entry) => entry.id === candidate.id) ?? null,
    promotedReservationId: promoted.order.id,
  })
}
