import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/dashboard_repository.dart';
import 'package:konekto_portal/models/dashboard_stats.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

String _currency(double value) => 'R\$ ${value.toStringAsFixed(2)}';

String _shortDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

const List<Color> _kCategoryPalette = [
  KonektoBrand.gold,
  Color(0xFF7CA9C9),
  Color(0xFF8FBF8A),
  Color(0xFFC98A8A),
  Color(0xFFC9A6E8),
  Color(0xFFE0B589),
];

/// Tela "Visão Geral" — primeira coisa que o staff vê ao entrar no portal.
/// Reúne os números que todo hotel/pousada quer acompanhar de relance:
/// ocupação, receita, funil de status dos pedidos, o que mais vende, e a
/// movimentação de check-in/check-out dos próximos dias. Tudo vem de uma
/// única chamada agregada (`GET /dashboard/stats`) pra não pesar o portal
/// trazendo o histórico de pedidos inteiro.
class DashboardOverviewPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const DashboardOverviewPage({super.key, required this.session, required this.authRepository});

  @override
  State<DashboardOverviewPage> createState() => _DashboardOverviewPageState();
}

class _DashboardOverviewPageState extends State<DashboardOverviewPage> {
  final _repository = DashboardRepository();

  bool _isLoading = true;
  String? _errorMessage;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Sessão expirada — saia e entre novamente.';
        _isLoading = false;
      });
      return;
    }
    try {
      final stats = await _repository.getStats(hotelId: widget.session.hotelId, token: token);
      if (!mounted) return;
      setState(() => _stats = stats);
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
    }
    final stats = _stats;
    if (stats == null) {
      return Center(child: Text(_errorMessage ?? 'Não foi possível carregar.', style: KonektoBrand.body(fontSize: 13.5)));
    }
    return RefreshIndicator(
      color: KonektoBrand.gold,
      backgroundColor: KonektoBrand.surface,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x1ADC2626),
                  border: Border.all(color: const Color(0x4DDC2626)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _KpiCard(
                  icon: Icons.meeting_room_outlined,
                  label: 'Ocupação',
                  value: '${(stats.occupancy.rate * 100).toStringAsFixed(0)}%',
                  detail: '${stats.occupancy.occupiedRooms} de ${stats.occupancy.totalRooms} quartos',
                ),
                _KpiCard(
                  icon: Icons.people_outline,
                  label: 'Hóspedes ativos',
                  value: '${stats.activeGuests}',
                  detail: 'com acesso ativo agora',
                ),
                _KpiCard(
                  icon: Icons.today_outlined,
                  label: 'Receita hoje',
                  value: _currency(stats.revenue.today),
                  detail: '${_currency(stats.revenue.last7Days)} nos últimos 7 dias',
                ),
                _KpiCard(
                  icon: Icons.payments_outlined,
                  label: 'Receita 30 dias',
                  value: _currency(stats.revenue.last30Days),
                  detail: 'ticket médio ${_currency(stats.averageTicketPerGuest)}/hóspede',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Receita nos últimos 14 dias',
              child: SizedBox(height: 220, child: _RevenueTrendChart(points: stats.revenueByDay)),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                final ordersCard = _SectionCard(
                  title: 'Pedidos por status (30 dias)',
                  child: SizedBox(height: 220, child: _OrdersStatusChart(stats: stats.ordersByStatus)),
                );
                final categoryCard = _SectionCard(
                  title: 'Receita por categoria (30 dias)',
                  child: SizedBox(
                    height: 220,
                    child: stats.revenueByCategory.isEmpty
                        ? Center(child: Text('Sem pedidos no período.', style: KonektoBrand.body(fontSize: 13)))
                        : _CategoryRevenueChart(categories: stats.revenueByCategory),
                  ),
                );
                if (isNarrow) {
                  return Column(children: [ordersCard, const SizedBox(height: 20), categoryCard]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ordersCard),
                    const SizedBox(width: 20),
                    Expanded(child: categoryCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Itens mais pedidos (30 dias)',
              child: stats.topItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Sem pedidos no período.', style: KonektoBrand.body(fontSize: 13)),
                    )
                  : _TopItemsList(items: stats.topItems),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                final checkIns = _SectionCard(
                  title: 'Chegadas nos próximos 7 dias',
                  child: _UpcomingStaysList(entries: stats.upcomingCheckIns, emptyLabel: 'Nenhuma chegada prevista.'),
                );
                final checkOuts = _SectionCard(
                  title: 'Saídas nos próximos 7 dias',
                  child: _UpcomingStaysList(entries: stats.upcomingCheckOuts, emptyLabel: 'Nenhuma saída prevista.'),
                );
                if (isNarrow) {
                  return Column(children: [checkIns, const SizedBox(height: 20), checkOuts]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: checkIns),
                    const SizedBox(width: 20),
                    Expanded(child: checkOuts),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  const _KpiCard({required this.icon, required this.label, required this.value, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: KonektoBrand.goldLight),
              const SizedBox(width: 8),
              Text(label, style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: KonektoBrand.display(fontSize: 24)),
          const SizedBox(height: 4),
          Text(detail, style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slateSoft)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: KonektoBrand.display(fontSize: 15)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  final List<RevenueDayPoint> points;

  const _RevenueTrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.every((point) => point.total == 0)) {
      return Center(child: Text('Sem receita registrada no período.', style: KonektoBrand.body(fontSize: 13)));
    }
    final maxValue = points.map((point) => point.total).reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.2;
    final step = (points.length / 7).ceil().clamp(1, points.length);
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(color: KonektoBrand.borderStrong, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length || index % step != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_shortDate(points[index].date), style: KonektoBrand.body(fontSize: 10.5, color: KonektoBrand.slate)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => KonektoBrand.surfaceAlt,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${_shortDate(points[group.x.toInt()].date)}\n${_currency(rod.toY)}',
              KonektoBrand.body(fontSize: 12, color: KonektoBrand.cream),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].total,
                  color: KonektoBrand.gold,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrdersStatusChart extends StatelessWidget {
  final OrdersByStatus stats;

  const _OrdersStatusChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.total == 0) {
      return Center(child: Text('Sem pedidos no período.', style: KonektoBrand.body(fontSize: 13)));
    }
    final entries = [
      (label: 'Pendente', value: stats.pending, color: KonektoBrand.goldLight),
      (label: 'Em andamento', value: stats.inProgress, color: const Color(0xFF7CA9C9)),
      (label: 'Concluído', value: stats.completed, color: const Color(0xFF8FBF8A)),
      (label: 'Cancelado', value: stats.cancelled, color: const Color(0xFFC98A8A)),
    ].where((entry) => entry.value > 0).toList();

    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final entry in entries)
                  PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: entry.color,
                    title: '${entry.value}',
                    radius: 34,
                    titleStyle: KonektoBrand.body(fontSize: 11.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in entries) _LegendRow(color: entry.color, label: entry.label, value: '${entry.value}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRevenueChart extends StatelessWidget {
  final List<CategoryRevenue> categories;

  const _CategoryRevenueChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (sum, category) => sum + category.total);
    final top = categories.take(_kCategoryPalette.length).toList();
    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < top.length; i++)
                  PieChartSectionData(
                    value: top[i].total,
                    color: _kCategoryPalette[i % _kCategoryPalette.length],
                    title: total > 0 ? '${(top[i].total / total * 100).toStringAsFixed(0)}%' : '',
                    radius: 34,
                    titleStyle: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < top.length; i++)
                _LegendRow(
                  color: _kCategoryPalette[i % _kCategoryPalette.length],
                  label: top[i].category,
                  value: _currency(top[i].total),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, overflow: TextOverflow.ellipsis, style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.cream)),
          ),
          const SizedBox(width: 8),
          Text(value, style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: KonektoBrand.slate)),
        ],
      ),
    );
  }
}

class _TopItemsList extends StatelessWidget {
  final List<TopOrderItem> items;

  const _TopItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxTotal = items.map((item) => item.total).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final item in items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text(item.itemName, overflow: TextOverflow.ellipsis, style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxTotal > 0 ? item.total / maxTotal : 0,
                      minHeight: 8,
                      backgroundColor: KonektoBrand.surfaceAlt,
                      valueColor: const AlwaysStoppedAnimation(KonektoBrand.gold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(
                    _currency(item.total),
                    textAlign: TextAlign.right,
                    style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: KonektoBrand.goldLight),
                  ),
                ),
              ],
            ),
          ),
          if (item != items.last) const SizedBox(height: 2),
        ],
      ],
    );
  }
}

class _UpcomingStaysList extends StatelessWidget {
  final List<UpcomingStayEntry> entries;
  final String emptyLabel;

  const _UpcomingStaysList({required this.entries, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(emptyLabel, style: KonektoBrand.body(fontSize: 13)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KonektoBrand.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(entry.roomNumber, style: KonektoBrand.body(fontSize: 12, fontWeight: FontWeight.w700, color: KonektoBrand.goldLight)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.guestNames.isEmpty ? 'Sem hóspede' : entry.guestNames.join(', '),
                        overflow: TextOverflow.ellipsis,
                        style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
                      ),
                      Text(_shortDate(entry.date), style: KonektoBrand.body(fontSize: 11.5, color: KonektoBrand.slate)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (entry != entries.last) const Divider(height: 1, color: KonektoBrand.borderStrong),
        ],
      ],
    );
  }
}
