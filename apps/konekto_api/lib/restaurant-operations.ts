import { Prisma, type OrderStatus, type PrismaClient, type Service } from '@/app/generated/prisma/client'
import {
  getHotelBasicNotificationsConfig,
  notifyRestaurantReservationCancelled,
  notifyRestaurantReservationConfirmed,
  notifyRestaurantReservationExpiryWarning,
} from '@/lib/basic-notifications'
import { prisma } from '@/lib/prisma'

export const RESTAURANT_OPERATIONS_DOC_NAME = 'restaurantOperations'
const TABLE_RESERVATION_ITEM_NAME = 'Reserva de mesa'

export type WaitlistEntryStatus = 'waiting' | 'promoted' | 'cancelled'

export interface RestaurantWaitlistEntry {
  id: string
  guestId: string
  guestName: string
  roomNumber: string
  partySize: number
  scheduledFor: string
  tableTypeId: string | null
  tableTypeLabel: string | null
  priority: number
  note: string | null
  source: 'staff'
  status: WaitlistEntryStatus
  promotedReservationId: string | null
  createdAt: string
  updatedAt: string
}

interface RestaurantServiceOperationsState {
  waitlist: RestaurantWaitlistEntry[]
}

interface RestaurantOperationsDoc {
  version: 1
  services: Record<string, RestaurantServiceOperationsState>
}

export interface RestaurantReservationSnapshot {
  id: string
  guestId: string
  guestName: string
  roomNumber: string
  status: OrderStatus
  scheduledFor: string
  createdAt: string
  note: string | null
  tableTypeId: string | null
  tableTypeLabel: string | null
  expiresAt: string | null
}

function createEmptyDoc(): RestaurantOperationsDoc {
  return { version: 1, services: {} }
}

function normalizeRestaurantOperationsDoc(input: unknown): RestaurantOperationsDoc {
  if (!input || typeof input !== 'object') return createEmptyDoc()

  const source = input as { version?: unknown; services?: unknown }
  const servicesRecord = source.services && typeof source.services === 'object' ? source.services : {}
  const normalizedServices: Record<string, RestaurantServiceOperationsState> = {}

  for (const [serviceId, rawState] of Object.entries(servicesRecord as Record<string, unknown>)) {
    const waitlistSource =
      rawState && typeof rawState === 'object' && Array.isArray((rawState as { waitlist?: unknown }).waitlist)
        ? ((rawState as { waitlist: unknown[] }).waitlist ?? [])
        : []

    normalizedServices[serviceId] = {
      waitlist: waitlistSource.flatMap((entry) => normalizeWaitlistEntry(entry)),
    }
  }

  return { version: 1, services: normalizedServices }
}

function normalizeWaitlistEntry(input: unknown): RestaurantWaitlistEntry[] {
  if (!input || typeof input !== 'object') return []

  const entry = input as Partial<RestaurantWaitlistEntry>
  if (
    typeof entry.id !== 'string' ||
    typeof entry.guestId !== 'string' ||
    typeof entry.guestName !== 'string' ||
    typeof entry.roomNumber !== 'string' ||
    typeof entry.partySize !== 'number' ||
    typeof entry.scheduledFor !== 'string' ||
    typeof entry.priority !== 'number' ||
    typeof entry.createdAt !== 'string' ||
    typeof entry.updatedAt !== 'string'
  ) {
    return []
  }

  return [
    {
      id: entry.id,
      guestId: entry.guestId,
      guestName: entry.guestName,
      roomNumber: entry.roomNumber,
      partySize: entry.partySize,
      scheduledFor: entry.scheduledFor,
      tableTypeId: typeof entry.tableTypeId === 'string' ? entry.tableTypeId : null,
      tableTypeLabel: typeof entry.tableTypeLabel === 'string' ? entry.tableTypeLabel : null,
      priority: entry.priority,
      note: typeof entry.note === 'string' ? entry.note : null,
      source: 'staff',
      status: entry.status === 'promoted' || entry.status === 'cancelled' ? entry.status : 'waiting',
      promotedReservationId: typeof entry.promotedReservationId === 'string' ? entry.promotedReservationId : null,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    },
  ]
}

export async function loadRestaurantOperationsDoc(hotelId: string): Promise<RestaurantOperationsDoc> {
  const existing = await prisma.hotelContent.findUnique({
    where: { hotelId_docName: { hotelId, docName: RESTAURANT_OPERATIONS_DOC_NAME } },
  })
  return normalizeRestaurantOperationsDoc(existing?.data)
}

export async function saveRestaurantOperationsDoc(hotelId: string, doc: RestaurantOperationsDoc): Promise<void> {
  await prisma.hotelContent.upsert({
    where: { hotelId_docName: { hotelId, docName: RESTAURANT_OPERATIONS_DOC_NAME } },
    create: { hotelId, docName: RESTAURANT_OPERATIONS_DOC_NAME, data: doc as unknown as Prisma.InputJsonValue },
    update: { data: doc as unknown as Prisma.InputJsonValue },
  })
}

export function getRestaurantServiceOperationsState(doc: RestaurantOperationsDoc, serviceId: string): RestaurantServiceOperationsState {
  return doc.services[serviceId] ?? { waitlist: [] }
}

export function setRestaurantServiceOperationsState(
  doc: RestaurantOperationsDoc,
  serviceId: string,
  state: RestaurantServiceOperationsState,
): RestaurantOperationsDoc {
  return {
    ...doc,
    services: {
      ...doc.services,
      [serviceId]: {
        waitlist: [...state.waitlist],
      },
    },
  }
}

export function sortWaitlistEntries(entries: RestaurantWaitlistEntry[]): RestaurantWaitlistEntry[] {
  return [...entries].sort((left, right) => {
    if (left.status !== right.status) return left.status === 'waiting' ? -1 : 1
    if (left.priority !== right.priority) return left.priority - right.priority
    return new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime()
  })
}

export function computeReservationExpiry(scheduledFor: Date, reservationExpiryMinutes: number | null | undefined): Date | null {
  if (!reservationExpiryMinutes || reservationExpiryMinutes <= 0) return null
  return new Date(scheduledFor.getTime() + reservationExpiryMinutes * 60 * 1000)
}

export async function expireRestaurantReservations(options: {
  hotelId: string
  serviceId: string
  reservationExpiryMinutes: number | null | undefined
  now?: Date
}): Promise<string[]> {
  if (!options.reservationExpiryMinutes || options.reservationExpiryMinutes <= 0) return []

  const now = options.now ?? new Date()
  const activeReservations = await prisma.order.findMany({
    where: {
      hotelId: options.hotelId,
      serviceId: options.serviceId,
      scheduledFor: { not: null },
      status: { in: ['pending', 'in_progress'] },
    },
    select: { id: true, guestId: true, scheduledFor: true },
  })

  const expiredReservations = activeReservations
    .filter((reservation) => {
      if (!reservation.scheduledFor) return false
      const expiresAt = computeReservationExpiry(reservation.scheduledFor, options.reservationExpiryMinutes)
      return expiresAt != null && expiresAt.getTime() <= now.getTime()
    })
  const expiredIds = expiredReservations.map((reservation) => reservation.id)

  if (expiredIds.length === 0) return []

  await prisma.order.updateMany({
    where: { id: { in: expiredIds } },
    data: { status: 'cancelled', statusSeenByGuest: false },
  })

  await Promise.all(
    expiredReservations.map((reservation) =>
      notifyRestaurantReservationCancelled({
        hotelId: options.hotelId,
        guestId: reservation.guestId,
        reservationId: reservation.id,
        scheduledFor: reservation.scheduledFor,
        reason: 'expired',
      }),
    ),
  )

  return expiredIds
}

export async function warnExpiringRestaurantReservations(options: {
  hotelId: string
  serviceId: string
  reservationExpiryMinutes: number | null | undefined
  now?: Date
}) {
  const notificationsConfig = await getHotelBasicNotificationsConfig(options.hotelId)
  const warningMinutes = notificationsConfig.domainPolicies.restaurantReservations.expiryWarningMinutes
  if (
    !options.reservationExpiryMinutes ||
    options.reservationExpiryMinutes <= 0 ||
    !warningMinutes ||
    warningMinutes <= 0 ||
    !notificationsConfig.channels.inApp ||
    !notificationsConfig.domainPolicies.restaurantReservations.notifyBeforeExpiry
  ) {
    return
  }

  const now = options.now ?? new Date()
  const activeReservations = await prisma.order.findMany({
    where: {
      hotelId: options.hotelId,
      serviceId: options.serviceId,
      scheduledFor: { not: null },
      status: { in: ['pending', 'in_progress'] },
    },
    select: { id: true, guestId: true, scheduledFor: true },
  })

  await Promise.all(
    activeReservations.map(async (reservation) => {
      if (!reservation.scheduledFor) return
      const expiresAt = computeReservationExpiry(reservation.scheduledFor, options.reservationExpiryMinutes)
      if (!expiresAt) return
      const millisUntilExpiry = expiresAt.getTime() - now.getTime()
      if (millisUntilExpiry <= 0 || millisUntilExpiry > warningMinutes * 60 * 1000) return

      await notifyRestaurantReservationExpiryWarning({
        hotelId: options.hotelId,
        guestId: reservation.guestId,
        reservationId: reservation.id,
        scheduledFor: reservation.scheduledFor,
        warningMinutes,
      })
    }),
  )
}

export async function listRestaurantReservations(options: {
  hotelId: string
  serviceId: string
  reservationExpiryMinutes: number | null | undefined
}): Promise<RestaurantReservationSnapshot[]> {
  const orders = await prisma.order.findMany({
    where: {
      hotelId: options.hotelId,
      serviceId: options.serviceId,
      scheduledFor: { not: null },
    },
    orderBy: [{ scheduledFor: 'asc' }, { createdAt: 'asc' }],
    include: {
      guest: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          stay: { select: { room: { select: { number: true } } } },
        },
      },
      tableType: { select: { id: true, label: true, seats: true } },
    },
  })

  return orders.map((order) => ({
    id: order.id,
    guestId: order.guest.id,
    guestName: `${order.guest.firstName} ${order.guest.lastName}`,
    roomNumber: order.guest.stay.room.number,
    status: order.status,
    scheduledFor: order.scheduledFor!.toISOString(),
    createdAt: order.createdAt.toISOString(),
    note: order.note,
    tableTypeId: order.tableTypeId,
    tableTypeLabel: order.tableType?.label ?? (order.tableType ? `${order.tableType.seats} lugares` : null),
    expiresAt: computeReservationExpiry(order.scheduledFor!, options.reservationExpiryMinutes)?.toISOString() ?? null,
  }))
}

export async function ensureRestaurantService(serviceId: string, hotelId: string): Promise<
  (Service & {
    tableTypes: { id: string; label: string | null; seats: number; quantity: number }[]
  }) | null
> {
  return prisma.service.findFirst({
    where: { id: serviceId, hotelId, type: 'restaurant' },
    include: { tableTypes: true },
  })
}

export async function ensureRestaurantReservationItem(client: PrismaClient, serviceId: string) {
  let item = await client.serviceItem.findFirst({ where: { serviceId, hidden: true } })
  if (!item) {
    item = await client.serviceItem.create({
      data: { serviceId, name: TABLE_RESERVATION_ITEM_NAME, description: '', hidden: true },
    })
  }
  return item
}

export async function createRestaurantReservationFromWaitlist(options: {
  hotelId: string
  serviceId: string
  guestId: string
  scheduledFor: Date
  tableTypeId: string | null
  note: string | null
}) {
  const service = await ensureRestaurantService(options.serviceId, options.hotelId)
  if (!service) {
    return { ok: false as const, error: 'service_not_found' as const }
  }

  const guest = await prisma.guest.findFirst({
    where: {
      id: options.guestId,
      hotelId: options.hotelId,
      status: 'active',
      stay: { status: 'active' },
    },
  })
  if (!guest) {
    return { ok: false as const, error: 'guest_not_found' as const }
  }

  const tableType = options.tableTypeId
    ? service.tableTypes.find((candidate) => candidate.id === options.tableTypeId) ?? null
    : null
  if (options.tableTypeId && !tableType) {
    return { ok: false as const, error: 'table_type_not_found' as const }
  }

  const reservationItem = await ensureRestaurantReservationItem(prisma, service.id)
  const baseData = {
    hotelId: options.hotelId,
    guestId: options.guestId,
    serviceId: service.id,
    serviceItemId: reservationItem.id,
    itemName: reservationItem.name,
    price: null,
    quantity: 1,
    note: options.note,
    scheduledFor: options.scheduledFor,
    tableTypeId: tableType?.id ?? null,
    statusSeenByGuest: false,
  }

  if (!tableType) {
    const order = await prisma.order.create({ data: baseData })
    await notifyRestaurantReservationConfirmed({
      hotelId: options.hotelId,
      guestId: options.guestId,
      reservationId: order.id,
      scheduledFor: options.scheduledFor,
    })
    return { ok: true as const, order }
  }

  const lockKey = `table:${tableType.id}:${options.scheduledFor.toISOString()}`
  const result = await prisma.$transaction(async (tx) => {
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${lockKey}))`

    const activeCount = await tx.order.count({
      where: {
        tableTypeId: tableType.id,
        scheduledFor: options.scheduledFor,
        status: { not: 'cancelled' },
      },
    })
    if (activeCount >= tableType.quantity) {
      return { kind: 'full' as const }
    }

    const item = await ensureRestaurantReservationItem(tx as PrismaClient, service.id)
    const order = await tx.order.create({
      data: {
        ...baseData,
        serviceItemId: item.id,
      },
    })
    return { kind: 'ok' as const, order }
  })

  if (result.kind === 'full') {
    return { ok: false as const, error: 'table_full' as const }
  }

  await notifyRestaurantReservationConfirmed({
    hotelId: options.hotelId,
    guestId: options.guestId,
    reservationId: result.order.id,
    scheduledFor: options.scheduledFor,
  })

  return { ok: true as const, order: result.order }
}
