import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import {
  createRestaurantReservationFromWaitlist,
  ensureRestaurantService,
  getRestaurantServiceOperationsState,
  loadRestaurantOperationsDoc,
  saveRestaurantOperationsDoc,
  setRestaurantServiceOperationsState,
} from '@/lib/restaurant-operations'

export const runtime = 'nodejs'

const patchWaitlistEntrySchema = z.discriminatedUnion('action', [
  z.object({
    action: z.literal('reprioritize'),
    priority: z.number().int().min(0).max(999),
  }),
  z.object({
    action: z.literal('cancel'),
  }),
  z.object({
    action: z.literal('promote'),
  }),
])

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ hotelId: string; serviceId: string; entryId: string }> },
) {
  const { hotelId, serviceId, entryId } = await params

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

  const parsed = patchWaitlistEntrySchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const service = await ensureRestaurantService(serviceId, hotelId)
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  const doc = await loadRestaurantOperationsDoc(hotelId)
  const state = getRestaurantServiceOperationsState(doc, serviceId)
  const current = state.waitlist.find((entry) => entry.id === entryId)
  if (!current) {
    return NextResponse.json({ error: 'waitlist_entry_not_found' }, { status: 404 })
  }

  if (parsed.data.action === 'reprioritize') {
    const nextPriority = parsed.data.priority
    const nextState = state.waitlist.map((entry) =>
      entry.id === entryId ? { ...entry, priority: nextPriority, updatedAt: new Date().toISOString() } : entry,
    )
    await saveRestaurantOperationsDoc(hotelId, setRestaurantServiceOperationsState(doc, serviceId, { waitlist: nextState }))
    return NextResponse.json(nextState.find((entry) => entry.id === entryId))
  }

  if (parsed.data.action === 'cancel') {
    const nextState = state.waitlist.map((entry) =>
      entry.id === entryId ? { ...entry, status: 'cancelled' as const, updatedAt: new Date().toISOString() } : entry,
    )
    await saveRestaurantOperationsDoc(hotelId, setRestaurantServiceOperationsState(doc, serviceId, { waitlist: nextState }))
    return NextResponse.json(nextState.find((entry) => entry.id === entryId))
  }

  if (current.status !== 'waiting') {
    return NextResponse.json({ error: 'waitlist_entry_not_available' }, { status: 409 })
  }

  const result = await createRestaurantReservationFromWaitlist({
    hotelId,
    serviceId,
    guestId: current.guestId,
    scheduledFor: new Date(current.scheduledFor),
    tableTypeId: current.tableTypeId,
    note: current.note,
  })

  if (!result.ok) {
    const status =
      result.error === 'table_full'
        ? 409
        : result.error === 'guest_not_found' || result.error === 'table_type_not_found'
          ? 404
          : 400
    return NextResponse.json({ error: result.error }, { status })
  }

  const nextState = state.waitlist.map((entry) =>
    entry.id === entryId
      ? {
          ...entry,
          status: 'promoted' as const,
          promotedReservationId: result.order.id,
          updatedAt: new Date().toISOString(),
        }
      : entry,
  )
  await saveRestaurantOperationsDoc(hotelId, setRestaurantServiceOperationsState(doc, serviceId, { waitlist: nextState }))

  return NextResponse.json({
    entry: nextState.find((entry) => entry.id === entryId),
    reservationId: result.order.id,
  })
}
