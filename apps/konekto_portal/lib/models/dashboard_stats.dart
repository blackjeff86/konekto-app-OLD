/// Ocupação atual do hotel — quantos quartos cadastrados existem vs.
/// quantos têm uma estadia ativa agora.
class OccupancyStats {
  final int totalRooms;
  final int occupiedRooms;
  final double rate;

  const OccupancyStats({required this.totalRooms, required this.occupiedRooms, required this.rate});

  factory OccupancyStats.fromJson(Map<String, dynamic> json) {
    return OccupancyStats(
      totalRooms: json['totalRooms'] as int,
      occupiedRooms: json['occupiedRooms'] as int,
      rate: (json['rate'] as num).toDouble(),
    );
  }
}

/// Receita consolidada (soma de `price * quantity` de pedidos não
/// cancelados) em três janelas fixas.
class RevenueStats {
  final double today;
  final double last7Days;
  final double last30Days;

  const RevenueStats({required this.today, required this.last7Days, required this.last30Days});

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      today: (json['today'] as num).toDouble(),
      last7Days: (json['last7Days'] as num).toDouble(),
      last30Days: (json['last30Days'] as num).toDouble(),
    );
  }
}

/// Um ponto da série de receita diária (14 dias mais recentes).
class RevenueDayPoint {
  final DateTime date;
  final double total;

  const RevenueDayPoint({required this.date, required this.total});

  factory RevenueDayPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDayPoint(date: DateTime.parse(json['date'] as String), total: (json['total'] as num).toDouble());
  }
}

/// Quantidade de pedidos por status, últimos 30 dias.
class OrdersByStatus {
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const OrdersByStatus({required this.pending, required this.inProgress, required this.completed, required this.cancelled});

  int get total => pending + inProgress + completed + cancelled;

  factory OrdersByStatus.fromJson(Map<String, dynamic> json) {
    return OrdersByStatus(
      pending: json['pending'] as int,
      inProgress: json['in_progress'] as int,
      completed: json['completed'] as int,
      cancelled: json['cancelled'] as int,
    );
  }
}

/// Receita agrupada por categoria de serviço (Restaurante, Serviço de
/// Quarto, Spa, etc.), últimos 30 dias, ordenada da maior pra menor.
class CategoryRevenue {
  final String category;
  final double total;

  const CategoryRevenue({required this.category, required this.total});

  factory CategoryRevenue.fromJson(Map<String, dynamic> json) {
    return CategoryRevenue(category: json['category'] as String, total: (json['total'] as num).toDouble());
  }
}

/// Um item do ranking de mais pedidos, últimos 30 dias.
class TopOrderItem {
  final String itemName;
  final int quantity;
  final double total;

  const TopOrderItem({required this.itemName, required this.quantity, required this.total});

  factory TopOrderItem.fromJson(Map<String, dynamic> json) {
    return TopOrderItem(
      itemName: json['itemName'] as String,
      quantity: json['quantity'] as int,
      total: (json['total'] as num).toDouble(),
    );
  }
}

/// Uma estadia com check-in ou check-out previsto pros próximos 7 dias.
class UpcomingStayEntry {
  final String stayId;
  final String roomNumber;
  final DateTime date;
  final List<String> guestNames;

  const UpcomingStayEntry({required this.stayId, required this.roomNumber, required this.date, required this.guestNames});

  factory UpcomingStayEntry.fromJson(Map<String, dynamic> json) {
    final rawGuestNames = json['guestNames'] as List<dynamic>;
    return UpcomingStayEntry(
      stayId: json['stayId'] as String,
      roomNumber: json['roomNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      guestNames: rawGuestNames.map((name) => name as String).toList(),
    );
  }
}

/// Estatísticas agregadas do hotel pra tela "Visão Geral" do dashboard —
/// tudo calculado no servidor (`GET /api/hotels/:hotelId/dashboard/stats`)
/// pra evitar trafegar todo o histórico de pedidos pro portal.
class DashboardStats {
  final OccupancyStats occupancy;
  final int activeGuests;
  final RevenueStats revenue;
  final List<RevenueDayPoint> revenueByDay;
  final OrdersByStatus ordersByStatus;
  final List<CategoryRevenue> revenueByCategory;
  final List<TopOrderItem> topItems;
  final double averageTicketPerGuest;
  final List<UpcomingStayEntry> upcomingCheckIns;
  final List<UpcomingStayEntry> upcomingCheckOuts;

  const DashboardStats({
    required this.occupancy,
    required this.activeGuests,
    required this.revenue,
    required this.revenueByDay,
    required this.ordersByStatus,
    required this.revenueByCategory,
    required this.topItems,
    required this.averageTicketPerGuest,
    required this.upcomingCheckIns,
    required this.upcomingCheckOuts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      occupancy: OccupancyStats.fromJson(json['occupancy'] as Map<String, dynamic>),
      activeGuests: json['activeGuests'] as int,
      revenue: RevenueStats.fromJson(json['revenue'] as Map<String, dynamic>),
      revenueByDay: (json['revenueByDay'] as List<dynamic>)
          .map((item) => RevenueDayPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      ordersByStatus: OrdersByStatus.fromJson(json['ordersByStatus'] as Map<String, dynamic>),
      revenueByCategory: (json['revenueByCategory'] as List<dynamic>)
          .map((item) => CategoryRevenue.fromJson(item as Map<String, dynamic>))
          .toList(),
      topItems: (json['topItems'] as List<dynamic>).map((item) => TopOrderItem.fromJson(item as Map<String, dynamic>)).toList(),
      averageTicketPerGuest: (json['averageTicketPerGuest'] as num).toDouble(),
      upcomingCheckIns: (json['upcomingCheckIns'] as List<dynamic>)
          .map((item) => UpcomingStayEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      upcomingCheckOuts: (json['upcomingCheckOuts'] as List<dynamic>)
          .map((item) => UpcomingStayEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
