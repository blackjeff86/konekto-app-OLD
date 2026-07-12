import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_role.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/features/dashboard/dashboard_overview_page.dart';
import 'package:konekto_portal/features/dashboard/widgets/placeholder_section_card.dart';
import 'package:konekto_portal/features/dashboard/widgets/portal_sidebar.dart';
import 'package:konekto_portal/features/guests/guests_page.dart';
import 'package:konekto_portal/features/orders/orders_page.dart';
import 'package:konekto_portal/features/rooms/rooms_page.dart';
import 'package:konekto_portal/features/settings/settings_page.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

const int _kVisaoGeralIndex = 0;
const int _kHospedesIndex = 1;
const int _kQuartosIndex = 2;
const int _kPedidosIndex = 3;

const DashboardSection _kVisaoGeralSection = (
  icon: Icons.dashboard_outlined,
  title: 'Visão Geral',
  description: 'Ocupação, receita e o que está movimentando o hotel.',
);
const DashboardSection _kHospedesSection = (
  icon: Icons.people_outline,
  title: 'Hóspedes',
  description: 'Conceda e revogue acesso, veja quem está hospedado.',
);
const DashboardSection _kQuartosSection = (
  icon: Icons.meeting_room_outlined,
  title: 'Quartos',
  description: 'Estadias com vários hóspedes, avisos e fechamento de conta.',
);
const DashboardSection _kPedidosSection = (
  icon: Icons.receipt_long_outlined,
  title: 'Pedidos',
  description: 'Acompanhe pedidos de room service, spa e restaurante.',
);
const DashboardSection _kConfiguracoesSection = (
  icon: Icons.settings_outlined,
  title: 'Configurações',
  description: 'Marca, cores, serviços e cardápio do seu hotel.',
);

class DashboardPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const DashboardPage({super.key, required this.session, required this.authRepository});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late final Future<String> _hotelNameFuture;
  late final List<DashboardSection> _sections;

  // `Configurações` só aparece pro `gerente` — `recepcao` não tem o que
  // fazer lá (a própria tela bloquearia o acesso, mas nem mostrar a aba
  // evita um beco sem saída na navegação).
  int? get _configuracoesIndex => widget.session.role == StaffRole.gerente ? _sections.length - 1 : null;

  @override
  void initState() {
    super.initState();
    _sections = [
      _kVisaoGeralSection,
      _kHospedesSection,
      _kQuartosSection,
      _kPedidosSection,
      if (widget.session.role == StaffRole.gerente) _kConfiguracoesSection,
    ];
    _hotelNameFuture = _loadHotelName();
  }

  Future<String> _loadHotelName() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/api/hotels/${widget.session.hotelId}'));
    if (response.statusCode != 200) {
      return widget.session.hotelId;
    }
    final config = jsonDecode(response.body) as Map<String, dynamic>;
    final hotelInfo = config['hotelInfo'] as Map<String, dynamic>?;
    return hotelInfo?['name'] as String? ?? widget.session.hotelId;
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];
    return Scaffold(
      backgroundColor: KonektoBrand.ink,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PortalSidebar(
            sections: _sections,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
            session: widget.session,
            authRepository: widget.authRepository,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Breadcrumb(hotelNameFuture: _hotelNameFuture, sectionTitle: section.title),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: switch (_selectedIndex) {
                      _kVisaoGeralIndex =>
                        DashboardOverviewPage(session: widget.session, authRepository: widget.authRepository),
                      _kHospedesIndex => GuestsPage(session: widget.session, authRepository: widget.authRepository),
                      _kQuartosIndex => RoomsPage(session: widget.session, authRepository: widget.authRepository),
                      _kPedidosIndex => OrdersPage(session: widget.session, authRepository: widget.authRepository),
                      _ when _selectedIndex == _configuracoesIndex =>
                        SettingsPage(session: widget.session, authRepository: widget.authRepository),
                      _ => PlaceholderSectionCard(icon: section.icon, title: section.title, description: section.description),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final Future<String> hotelNameFuture;
  final String sectionTitle;

  const _Breadcrumb({required this.hotelNameFuture, required this.sectionTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KonektoBrand.borderStrong)),
      ),
      child: FutureBuilder<String>(
        future: hotelNameFuture,
        builder: (context, snapshot) {
          final hotelName = snapshot.data ?? '...';
          return RichText(
            text: TextSpan(
              style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.slate),
              children: [
                TextSpan(text: hotelName),
                const TextSpan(text: '  /  '),
                TextSpan(text: sectionTitle, style: KonektoBrand.body(fontSize: 13, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
              ],
            ),
          );
        },
      ),
    );
  }
}
