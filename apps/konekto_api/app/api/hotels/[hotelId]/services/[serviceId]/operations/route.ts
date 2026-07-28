import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'
import {
  ensureRestaurantService,
  expireRestaurantReservations,
  getRestaurantServiceOperationsState,
  listRestaurantReservations,
  loadRestaurantOperationsDoc,
  saveRestaurantOperationsDoc,
  setRestaurantServiceOperationsState,
  sortWaitlistEntries,
  warnExpiringRestaurantReservations,
  type RestaurantWaitlistEntry,
} from '@/lib/restaurant-operations'
import { prisma } from '@/lib/prisma'

export const runtime = 'nodejs'

const createWaitlistEntrySchema = z.object({
  guestId: z.string().min(1),
  partySize: z.number().int().min(1).max(40),
  scheduledFor: z.coerce.date(),
  tableTypeId: z.string().min(1).nullable().optional(),
  priority: z.number().int().min(0).max(999).default(100),
  note: z.string().trim().max(500).nullable().optional(),
})

function getRestaurantConfiguration(service: { moduleId: string | null; hotelId: string }, modules: unknown) {
  if (!service.moduleId || !modules || typeof modules !== 'object') return {}
  const moduleState = (modules as Record<string, unknown>)[service.moduleId]
  if (!moduleState || typeof moduleState !== 'object') return {}
  const configuration = (moduleState as { configuration?: unknown }).configuration
  return configuration && typeof configuration === 'object' ? (configuration as Record<string, unknown>) : {}
}

export async function GET(
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

  const service = await ensureRestaurantService(serviceId, hotelId)
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  const hotel = await prisma.hotel.findUnique({
    where: { id: hotelId },
    select: { config: true },
  })

  const restaurantConfig = getRestaurantConfiguration(service, (hotel?.config as { modules?: unknown } | null)?.modules)
  const reservationExpiryMinutes =
    typeof restaurantConfig.reservationExpiryMinutes === 'number' ? restaurantConfig.reservationExpiryMinutes : null

  await expireRestaurantReservations({ hotelId, serviceId, reservationExpiryMinutes })
  await warnExpiringRestaurantReservations({ hotelId, serviceId, reservationExpiryMinutes })

  const [doc, reservations] = await Promise.all([
    loadRestaurantOperationsDoc(hotelId),
    listRestaurantReservations({ hotelId, serviceId, reservationExpiryMinutes }),
  ])

  const state = getRestaurantServiceOperationsState(doc, serviceId)

  return NextResponse.json({
    service: {
      id: service.id,
      name: service.name,
      tableTypes: service.tableTypes.map((tableType) => ({
        id: tableType.id,
        label: tableType.label,
        seats: tableType.seats,
        quantity: tableType.quantity,
      })),
    },
    configuration: {
      waitlistEnabled: restaurantConfig.waitlistEnabled === true,
      waitlistCapacity: typeof restaurantConfig.waitlistCapacity === 'number' ? restaurantConfig.waitlistCapacity : null,
      reservationExpiryMinutes,
    },
    reservations,
    waitlist: sortWaitlistEntries(state.waitlist),
  })
}

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

  const parsed = createWaitlistEntrySchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  }

  const service = await ensureRestaurantService(serviceId, hotelId)
  if (!service) {
    return NextResponse.json({ error: 'service_not_found' }, { status: 404 })
  }

  const guest = await prisma.guest.findFirst({
    where: {
      id: parsed.data.guestId,
      hotelId,
      status: 'active',
      stay: { status: 'active' },
    },
    include: { stay: { select: { room: { select: { number: true } } } } },
  })
  if (!guest) {
    return NextResponse.json({ error: 'guest_not_found' }, { status: 404 })
  }

  const hotel = await prisma.hotel.findUnique({
    where: { id: hotelId },
    select: { config: true },
  })
  const restaurantConfig = getRestaurantConfiguration(service, (hotel?.config as { modules?: unknown } | null)?.modules)

  if (restaurantConfig.waitlistEnabled !== true) {
    return NextResponse.json({ error: 'waitlist_disabled' }, { status: 409 })
  }

  const tableType =
    parsed.data.tableTypeId != null
      ? service.tableTypes.find((candidate) => candidate.id === parsed.data.tableTypeId) ?? null
      : null
  if (parsed.data.tableTypeId != null && !tableType) {
    return NextResponse.json({ error: 'table_type_not_found' }, { status: 404 })
  }

  const doc = await loadRestaurantOperationsDoc(hotelId)
  const state = getRestaurantServiceOperationsState(doc, serviceId)
  const activeEntries = state.waitlist.filter((entry) => entry.status === 'waiting')
  const waitlistCapacity = typeof restaurantConfig.waitlistCapacity === 'number' ? restaurantConfig.waitlistCapacity : null

  if (waitlistCapacity != null && activeEntries.length >= waitlistCapacity) {
    return NextResponse.json({ error: 'waitlist_full' }, { status: 409 })
  }

  const nowIso = new Date().toISOString()
  const entry: RestaurantWaitlistEntry = {
    id: crypto.randomUUID(),
    guestId: guest.id,
    guestName: `${guest.firstName} ${guest.lastName}`,
    roomNumber: guest.stay.room.number,
    partySize: parsed.data.partySize,
    scheduledFor: parsed.data.scheduledFor.toISOString(),
    tableTypeId: tableType?.id ?? null,
    tableTypeLabel: tableType?.label ?? (tableType ? `${tableType.seats} lugares` : null),
    priority: parsed.data.priority,
    note: parsed.data.note ?? null,
    source: 'staff',
    status: 'waiting',
    promotedReservationId: null,
    createdAt: nowIso,
    updatedAt: nowIso,
  }

  await saveRestaurantOperationsDoc(
    hotelId,
    setRestaurantServiceOperationsState(doc, serviceId, {
      waitlist: [...state.waitlist, entry],
    }),
  )

  return NextResponse.json(entry, { status: 201 })
}
