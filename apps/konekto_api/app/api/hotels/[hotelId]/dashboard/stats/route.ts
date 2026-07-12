import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { requireStaffRole, AuthGuardError } from '@/lib/auth-guard'

export const runtime = 'nodejs'

const DAYS_IN_TREND = 14
const LOOKBACK_DAYS = 30
const UPCOMING_WINDOW_DAYS = 7
const TOP_ITEMS_LIMIT = 5

function startOfDay(date: Date): Date {
  const copy = new Date(date)
  copy.setHours(0, 0, 0, 0)
  return copy
}

function addDays(date: Date, days: number): Date {
  const copy = new Date(date)
  copy.setDate(copy.getDate() + days)
  return copy
}

function dateKey(date: Date): string {
  return date.toISOString().slice(0, 10)
}

// Agrega tudo que um dashboard de hotel/pousada precisa numa chamada só:
// ocupação atual, receita (hoje/7d/30d + série diária), pedidos por status,
// receita por categoria de serviço, itens mais pedidos, ticket médio por
// hóspede, e check-ins/check-outs dos próximos 7 dias. Tudo calculado no
// servidor pra não precisar trafegar todo o histórico de pedidos pro portal.
export async function GET(request: NextRequest, { params }: { params: Promise<{ hotelId: string }> }) {
  const { hotelId } = await params

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

  const today = startOfDay(new Date())
  const trendStart = addDays(today, -(DAYS_IN_TREND - 1))
  const lookbackStart = addDays(today, -(LOOKBACK_DAYS - 1))
  const upcomingEnd = addDays(today, UPCOMING_WINDOW_DAYS)

  const [rooms, activeGuestsCount, orders, upcomingCheckIns, upcomingCheckOuts] = await Promise.all([
    prisma.room.findMany({
      where: { hotelId },
      select: { id: true, stays: { where: { status: 'active' }, select: { id: true }, take: 1 } },
    }),
    prisma.guest.count({ where: { hotelId, status: 'active' } }),
    prisma.order.findMany({
      where: { hotelId, createdAt: { gte: lookbackStart } },
      select: {
        price: true,
        quantity: true,
        status: true,
        itemName: true,
        serviceId: true,
        createdAt: true,
        guestId: true,
      },
    }),
    prisma.stay.findMany({
      where: { hotelId, checkInDate: { gte: today, lte: upcomingEnd } },
      select: {
        id: true,
        checkInDate: true,
        room: { select: { number: true } },
        guests: { select: { firstName: true, lastName: true } },
      },
      orderBy: { checkInDate: 'asc' },
    }),
    prisma.stay.findMany({
      where: { hotelId, status: 'active', checkOutDate: { gte: today, lte: upcomingEnd } },
      select: {
        id: true,
        checkOutDate: true,
        room: { select: { number: true } },
        guests: { select: { firstName: true, lastName: true } },
      },
      orderBy: { checkOutDate: 'asc' },
    }),
  ])

  const totalRooms = rooms.length
  const occupiedRooms = rooms.filter((room) => room.stays.length > 0).length

  const serviceIds = Array.from(new Set(orders.map((order) => order.serviceId)))
  const services = serviceIds.length
    ? await prisma.service.findMany({ where: { id: { in: serviceIds }, hotelId }, select: { id: true, category: true } })
    : []
  const categoryByServiceId = new Map(services.map((service) => [service.id, service.category]))

  const billableOrders = orders.filter((order) => order.status !== 'cancelled' && order.price != null)
  const orderRevenue = (order: (typeof orders)[number]): number => (order.price ?? 0) * order.quantity

  let revenueToday = 0
  let revenueLast7Days = 0
  let revenueLast30Days = 0
  const revenueByDayMap = new Map<string, number>()
  for (let i = 0; i < DAYS_IN_TREND; i++) revenueByDayMap.set(dateKey(addDays(trendStart, i)), 0)
  const revenueByCategoryMap = new Map<string, number>()
  const itemStatsMap = new Map<string, { quantity: number; total: number }>()
  const billableGuestIds = new Set<string>()
  const sevenDaysAgo = addDays(today, -6)

  for (const order of billableOrders) {
    const revenue = orderRevenue(order)
    revenueLast30Days += revenue
    if (order.createdAt >= today) revenueToday += revenue
    if (order.createdAt >= sevenDaysAgo) revenueLast7Days += revenue

    const key = dateKey(startOfDay(order.createdAt))
    if (revenueByDayMap.has(key)) revenueByDayMap.set(key, (revenueByDayMap.get(key) ?? 0) + revenue)

    const category = categoryByServiceId.get(order.serviceId) ?? 'Outros'
    revenueByCategoryMap.set(category, (revenueByCategoryMap.get(category) ?? 0) + revenue)

    const itemStats = itemStatsMap.get(order.itemName) ?? { quantity: 0, total: 0 }
    itemStats.quantity += order.quantity
    itemStats.total += revenue
    itemStatsMap.set(order.itemName, itemStats)

    billableGuestIds.add(order.guestId)
  }

  const ordersByStatus = { pending: 0, in_progress: 0, completed: 0, cancelled: 0 }
  for (const order of orders) ordersByStatus[order.status] += 1

  const revenueByDay = Array.from(revenueByDayMap.entries()).map(([date, total]) => ({ date, total }))
  const revenueByCategory = Array.from(revenueByCategoryMap.entries())
    .map(([category, total]) => ({ category, total }))
    .sort((a, b) => b.total - a.total)
  const topItems = Array.from(itemStatsMap.entries())
    .map(([itemName, stats]) => ({ itemName, quantity: stats.quantity, total: stats.total }))
    .sort((a, b) => b.total - a.total)
    .slice(0, TOP_ITEMS_LIMIT)

  const averageTicketPerGuest = billableGuestIds.size > 0 ? revenueLast30Days / billableGuestIds.size : 0

  const shapeStayEntry = <T extends { id: string; room: { number: string }; guests: { firstName: string; lastName: string }[] }>(
    stay: T,
    dateField: 'checkInDate' | 'checkOutDate',
  ) => ({
    stayId: stay.id,
    roomNumber: stay.room.number,
    date: (stay as unknown as Record<string, Date>)[dateField].toISOString(),
    guestNames: stay.guests.map((guest) => `${guest.firstName} ${guest.lastName}`),
  })

  return NextResponse.json({
    occupancy: { totalRooms, occupiedRooms, rate: totalRooms > 0 ? occupiedRooms / totalRooms : 0 },
    activeGuests: activeGuestsCount,
    revenue: {
      today: revenueToday,
      last7Days: revenueLast7Days,
      last30Days: revenueLast30Days,
    },
    revenueByDay,
    ordersByStatus,
    revenueByCategory,
    topItems,
    averageTicketPerGuest,
    upcomingCheckIns: upcomingCheckIns.map((stay) => shapeStayEntry(stay, 'checkInDate')),
    upcomingCheckOuts: upcomingCheckOuts.map((stay) => shapeStayEntry(stay, 'checkOutDate')),
  })
}
