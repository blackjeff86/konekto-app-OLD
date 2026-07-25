/** Portado de apps/konekto_portal/lib/models/dashboard_stats.dart. */

export interface OccupancyStats {
  totalRooms: number
  occupiedRooms: number
  rate: number
}

export interface RevenueStats {
  today: number
  last7Days: number
  last30Days: number
}

export interface RevenueDayPoint {
  date: string
  total: number
}

export interface OrdersByStatus {
  pending: number
  in_progress: number
  completed: number
  cancelled: number
}

export function ordersByStatusTotal(stats: OrdersByStatus): number {
  return stats.pending + stats.in_progress + stats.completed + stats.cancelled
}

export interface CategoryRevenue {
  category: string
  total: number
}

export interface TopOrderItem {
  itemName: string
  quantity: number
  total: number
}

export interface UpcomingStayEntry {
  stayId: string
  roomNumber: string
  date: string
  guestNames: string[]
}

export interface DashboardStats {
  occupancy: OccupancyStats
  activeGuests: number
  revenue: RevenueStats
  revenueByDay: RevenueDayPoint[]
  ordersByStatus: OrdersByStatus
  revenueByCategory: CategoryRevenue[]
  topItems: TopOrderItem[]
  averageTicketPerGuest: number
  upcomingCheckIns: UpcomingStayEntry[]
  upcomingCheckOuts: UpcomingStayEntry[]
}
