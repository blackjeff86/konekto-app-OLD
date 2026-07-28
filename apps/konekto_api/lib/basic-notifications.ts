import type { PrismaClient } from '@/app/generated/prisma/client'
import { readHotelModuleConfiguration } from '@/lib/hotel-modules'
import { prisma } from '@/lib/prisma'

type NotificationChannel = 'in_app' | 'browser' | 'email' | 'whatsapp'

type BasicNotificationsChannels = {
  inApp: boolean
  browser: boolean
  email: boolean
  whatsapp: boolean
}

type RestaurantReservationPolicy = {
  notifyOnConfirmed: boolean
  notifyOnCancelled: boolean
  notifyOnRescheduled: boolean
  notifyBeforeExpiry: boolean
  expiryWarningMinutes: number | null
}

type RoomServiceOrdersPolicy = {
  notifyOnAccepted: boolean
  notifyOnCompleted: boolean
  notifyOnCancelled: boolean
  notifyOnStaffConsumptionRecorded: boolean
}

export interface BasicNotificationsConfig {
  channels: BasicNotificationsChannels
  domainPolicies: {
    roomServiceOrders: RoomServiceOrdersPolicy
    restaurantReservations: RestaurantReservationPolicy
  }
}

const DEFAULT_BASIC_NOTIFICATIONS_CONFIG: BasicNotificationsConfig = {
  channels: {
    inApp: true,
    browser: false,
    email: false,
    whatsapp: false,
  },
  domainPolicies: {
    roomServiceOrders: {
      notifyOnAccepted: true,
      notifyOnCompleted: true,
      notifyOnCancelled: true,
      notifyOnStaffConsumptionRecorded: true,
    },
    restaurantReservations: {
      notifyOnConfirmed: true,
      notifyOnCancelled: true,
      notifyOnRescheduled: true,
      notifyBeforeExpiry: true,
      expiryWarningMinutes: 15,
    },
  },
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

export function resolveBasicNotificationsConfig(hotelConfig: unknown): BasicNotificationsConfig {
  const config = isRecord(hotelConfig) ? hotelConfig : {}
  const configuration = readHotelModuleConfiguration(config, 'basic_notifications')
  const channels = isRecord(configuration.channels) ? configuration.channels : {}
  const domainPolicies = isRecord(configuration.domainPolicies) ? configuration.domainPolicies : {}
  const roomServiceOrders = isRecord(domainPolicies.roomServiceOrders) ? domainPolicies.roomServiceOrders : {}
  const restaurantReservations = isRecord(domainPolicies.restaurantReservations)
    ? domainPolicies.restaurantReservations
    : {}

  return {
    channels: {
      inApp: typeof channels.inApp === 'boolean' ? channels.inApp : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.channels.inApp,
      browser: typeof channels.browser === 'boolean' ? channels.browser : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.channels.browser,
      email: typeof channels.email === 'boolean' ? channels.email : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.channels.email,
      whatsapp:
        typeof channels.whatsapp === 'boolean'
          ? channels.whatsapp
          : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.channels.whatsapp,
    },
    domainPolicies: {
      roomServiceOrders: {
        notifyOnAccepted:
          typeof roomServiceOrders.notifyOnAccepted === 'boolean'
            ? roomServiceOrders.notifyOnAccepted
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.roomServiceOrders.notifyOnAccepted,
        notifyOnCompleted:
          typeof roomServiceOrders.notifyOnCompleted === 'boolean'
            ? roomServiceOrders.notifyOnCompleted
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.roomServiceOrders.notifyOnCompleted,
        notifyOnCancelled:
          typeof roomServiceOrders.notifyOnCancelled === 'boolean'
            ? roomServiceOrders.notifyOnCancelled
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.roomServiceOrders.notifyOnCancelled,
        notifyOnStaffConsumptionRecorded:
          typeof roomServiceOrders.notifyOnStaffConsumptionRecorded === 'boolean'
            ? roomServiceOrders.notifyOnStaffConsumptionRecorded
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.roomServiceOrders.notifyOnStaffConsumptionRecorded,
      },
      restaurantReservations: {
        notifyOnConfirmed:
          typeof restaurantReservations.notifyOnConfirmed === 'boolean'
            ? restaurantReservations.notifyOnConfirmed
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.restaurantReservations.notifyOnConfirmed,
        notifyOnCancelled:
          typeof restaurantReservations.notifyOnCancelled === 'boolean'
            ? restaurantReservations.notifyOnCancelled
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.restaurantReservations.notifyOnCancelled,
        notifyOnRescheduled:
          typeof restaurantReservations.notifyOnRescheduled === 'boolean'
            ? restaurantReservations.notifyOnRescheduled
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.restaurantReservations.notifyOnRescheduled,
        notifyBeforeExpiry:
          typeof restaurantReservations.notifyBeforeExpiry === 'boolean'
            ? restaurantReservations.notifyBeforeExpiry
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.restaurantReservations.notifyBeforeExpiry,
        expiryWarningMinutes:
          typeof restaurantReservations.expiryWarningMinutes === 'number'
            ? restaurantReservations.expiryWarningMinutes
            : DEFAULT_BASIC_NOTIFICATIONS_CONFIG.domainPolicies.restaurantReservations.expiryWarningMinutes,
      },
    },
  }
}

export async function getHotelBasicNotificationsConfig(hotelId: string): Promise<BasicNotificationsConfig> {
  const hotel = await prisma.hotel.findUnique({
    where: { id: hotelId },
    select: { config: true },
  })
  return resolveBasicNotificationsConfig(hotel?.config)
}

export async function createGuestNotification(
  client: PrismaClient,
  input: {
    hotelId: string
    guestId: string
    moduleId?: string
    channel?: NotificationChannel
    title: string
    body: string
    relatedEntityType?: string | null
    relatedEntityId?: string | null
    dedupeKey?: string | null
  },
) {
  const dedupeKey = input.dedupeKey ?? null
  if (dedupeKey) {
    const existing = await client.guestNotification.findFirst({
      where: { guestId: input.guestId, dedupeKey },
    })
    if (existing) return existing
  }

  return client.guestNotification.create({
    data: {
      hotelId: input.hotelId,
      guestId: input.guestId,
      moduleId: input.moduleId ?? 'basic_notifications',
      channel: input.channel ?? 'in_app',
      title: input.title,
      body: input.body,
      relatedEntityType: input.relatedEntityType ?? null,
      relatedEntityId: input.relatedEntityId ?? null,
      dedupeKey,
    },
  })
}

export async function listGuestNotifications(client: PrismaClient, guestId: string) {
  return client.guestNotification.findMany({
    where: { guestId },
    orderBy: { createdAt: 'desc' },
  })
}

export async function countUnreadGuestNotifications(client: PrismaClient, guestId: string) {
  return client.guestNotification.count({
    where: { guestId, status: 'unread' },
  })
}

export async function markGuestNotificationsRead(client: PrismaClient, guestId: string) {
  await client.guestNotification.updateMany({
    where: { guestId, status: 'unread' },
    data: { status: 'read', readAt: new Date() },
  })
}

export async function notifyRestaurantReservationConfirmed(options: {
  hotelId: string
  guestId: string
  reservationId: string
  scheduledFor: Date
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.restaurantReservations.notifyOnConfirmed) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Reserva confirmada',
    body: `Sua reserva do restaurante para ${formatNotificationDate(options.scheduledFor)} foi confirmada.`,
    relatedEntityType: 'order',
    relatedEntityId: options.reservationId,
    dedupeKey: `restaurant-confirmed:${options.reservationId}`,
  })
}

export async function notifyRestaurantReservationCancelled(options: {
  hotelId: string
  guestId: string
  reservationId: string
  scheduledFor: Date | null
  reason: 'expired' | 'cancelled' | 'released'
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.restaurantReservations.notifyOnCancelled) return

  const reasonText =
    options.reason === 'expired'
      ? 'foi cancelada por expiração do tempo de chegada'
      : options.reason === 'released'
        ? 'foi encerrada pela equipe do hotel'
        : 'foi cancelada'

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Reserva cancelada',
    body: options.scheduledFor
      ? `Sua reserva do restaurante para ${formatNotificationDate(options.scheduledFor)} ${reasonText}.`
      : `Sua reserva do restaurante ${reasonText}.`,
    relatedEntityType: 'order',
    relatedEntityId: options.reservationId,
    dedupeKey: `restaurant-cancelled:${options.reason}:${options.reservationId}`,
  })
}

export async function notifyRestaurantReservationRescheduled(options: {
  hotelId: string
  guestId: string
  reservationId: string
  scheduledFor: Date
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.restaurantReservations.notifyOnRescheduled) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Reserva reagendada',
    body: `Sua reserva do restaurante foi reagendada para ${formatNotificationDate(options.scheduledFor)}.`,
    relatedEntityType: 'order',
    relatedEntityId: options.reservationId,
    dedupeKey: `restaurant-rescheduled:${options.reservationId}:${options.scheduledFor.toISOString()}`,
  })
}

export async function notifyRestaurantReservationExpiryWarning(options: {
  hotelId: string
  guestId: string
  reservationId: string
  scheduledFor: Date
  warningMinutes: number
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.restaurantReservations.notifyBeforeExpiry) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Reserva perto de expirar',
    body: `Sua reserva do restaurante para ${formatNotificationDate(options.scheduledFor)} expira em ${options.warningMinutes} minuto(s) se nao houver confirmacao.`,
    relatedEntityType: 'order',
    relatedEntityId: options.reservationId,
    dedupeKey: `restaurant-expiry-warning:${options.reservationId}:${options.warningMinutes}`,
  })
}

export async function notifyRoomServiceOrderAccepted(options: {
  hotelId: string
  guestId: string
  orderId: string
  itemName: string
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.roomServiceOrders.notifyOnAccepted) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Pedido em preparo',
    body: `Seu pedido de ${options.itemName} foi aceito pela equipe e entrou em preparo.`,
    relatedEntityType: 'order',
    relatedEntityId: options.orderId,
    dedupeKey: `room-service-accepted:${options.orderId}`,
  })
}

export async function notifyRoomServiceOrderCompleted(options: {
  hotelId: string
  guestId: string
  orderId: string
  itemName: string
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.roomServiceOrders.notifyOnCompleted) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Pedido concluído',
    body: `Seu pedido de ${options.itemName} foi concluído pela equipe do hotel.`,
    relatedEntityType: 'order',
    relatedEntityId: options.orderId,
    dedupeKey: `room-service-completed:${options.orderId}`,
  })
}

export async function notifyRoomServiceOrderCancelled(options: {
  hotelId: string
  guestId: string
  orderId: string
  itemName: string
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.roomServiceOrders.notifyOnCancelled) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Pedido cancelado',
    body: `Seu pedido de ${options.itemName} foi cancelado.`,
    relatedEntityType: 'order',
    relatedEntityId: options.orderId,
    dedupeKey: `room-service-cancelled:${options.orderId}`,
  })
}

export async function notifyStaffRecordedMinibarConsumption(options: {
  hotelId: string
  guestId: string
  orderId: string
  itemName: string
  quantity: number
}) {
  const config = await getHotelBasicNotificationsConfig(options.hotelId)
  if (!config.channels.inApp || !config.domainPolicies.roomServiceOrders.notifyOnStaffConsumptionRecorded) return

  await createGuestNotification(prisma, {
    hotelId: options.hotelId,
    guestId: options.guestId,
    moduleId: 'basic_notifications',
    title: 'Consumo de frigobar lançado',
    body: `A recepção lançou ${options.quantity} unidade(s) de ${options.itemName} no seu consumo.`,
    relatedEntityType: 'order',
    relatedEntityId: options.orderId,
    dedupeKey: `room-service-minibar-recorded:${options.orderId}`,
  })
}

function formatNotificationDate(value: Date): string {
  const day = value.getUTCDate().toString().padStart(2, '0')
  const month = (value.getUTCMonth() + 1).toString().padStart(2, '0')
  const year = value.getUTCFullYear()
  const hours = value.getUTCHours().toString().padStart(2, '0')
  const minutes = value.getUTCMinutes().toString().padStart(2, '0')
  return `${day}/${month}/${year} às ${hours}:${minutes}`
}
