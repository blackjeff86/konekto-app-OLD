import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_role.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/orders_repository.dart';
import 'package:konekto_portal/data/stays_repository.dart';
import 'package:konekto_portal/features/customers/customers_page.dart';
import 'package:konekto_portal/features/dashboard/browser_notifications.dart';
import 'package:konekto_portal/features/dashboard/dashboard_overview_page.dart';
import 'package:konekto_portal/features/dashboard/new_order_sound.dart';
import 'package:konekto_portal/features/dashboard/widgets/placeholder_section_card.dart';
import 'package:konekto_portal/features/dashboard/widgets/portal_sidebar.dart';
import 'package:konekto_portal/features/guests/guests_page.dart';
import 'package:konekto_portal/features/orders/orders_page.dart';
import 'package:konekto_portal/features/rooms/rooms_page.dart';
import 'package:konekto_portal/features/settings/settings_page.dart';
import 'package:konekto_portal/features/support/support_page.dart';
import 'package:konekto_portal/data/support_repository.dart';
import 'package:konekto_portal/models/order.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

const Duration _kOrderPollInterval = Duration(seconds: 5);

const int _kVisaoGeralIndex = 0;
const int _kHospedesIndex = 1;
const int _kClientesIndex = 2;
const int _kQuartosIndex = 3;
const int _kPedidosIndex = 4;
const int _kSuporteIndex = 5;

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
const DashboardSection _kClientesSection = (
  icon: Icons.groups_outlined,
  title: 'Clientes',
  description: 'Histórico completo de quem já se hospedou e quanto gastou.',
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
const DashboardSection _kSuporteSection = (
  icon: Icons.support_agent_outlined,
  title: 'Suporte',
  description: 'Fale direto com a equipe do Konekto.',
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

  final _ordersRepository = OrdersRepository();
  final _staysRepository = StaysRepository();
  Timer? _orderPollTimer;
  bool _ordersLoading = true;
  String? _ordersError;
  List<Order> _orders = const [];

  // Preenchido no primeiro carregamento bem-sucedido — nunca notifica pelos
  // pedidos que já existiam quando o portal abriu, só pelos que chegarem
  // depois.
  Set<String> _knownOrderIds = {};
  bool _knownOrderIdsSeeded = false;

  int _unreadMessagesCount = 0;
  bool _unreadMessagesCountSeeded = false;

  final _supportRepository = SupportRepository();
  int _unreadSupportCount = 0;

  int get _pendingOrderCount => _orders.where((order) => order.status == OrderStatus.pending).length;

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
      _kClientesSection,
      _kQuartosSection,
      _kPedidosSection,
      _kSuporteSection,
      if (widget.session.role == StaffRole.gerente) _kConfiguracoesSection,
    ];
    _hotelNameFuture = _loadHotelName();

    BrowserNotifications.requestPermissionIfNeeded();
    _loadOrders();
    _loadUnreadMessagesCount();
    _loadUnreadSupportCount();
    _orderPollTimer = Timer.periodic(_kOrderPollInterval, (_) {
      _loadOrders(silent: true);
      _loadUnreadMessagesCount();
      _loadUnreadSupportCount();
    });
  }

  @override
  void dispose() {
    _orderPollTimer?.cancel();
    super.dispose();
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

  /// Roda continuamente (não só quando a aba Pedidos está selecionada), pra
  /// alertar sobre pedido novo em qualquer seção do portal.
  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) setState(() => _ordersLoading = true);
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      if (mounted) setState(() => _ordersError = 'Sessão expirada — saia e entre novamente.');
      if (!silent && mounted) setState(() => _ordersLoading = false);
      return;
    }
    try {
      final orders = await _ordersRepository.listOrders(hotelId: widget.session.hotelId, token: token);
      if (!mounted) return;

      if (_knownOrderIdsSeeded) {
        final newOrders = orders.where((order) => !_knownOrderIds.contains(order.id)).toList();
        if (newOrders.isNotEmpty) _notifyNewOrders(newOrders);
      }
      _knownOrderIds = orders.map((order) => order.id).toSet();
      _knownOrderIdsSeeded = true;

      setState(() {
        _orders = orders;
        _ordersError = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _ordersError = error.message);
    } finally {
      if (mounted && !silent) setState(() => _ordersLoading = false);
    }
  }

  /// Roda continuamente igual `_loadOrders` — alerta quando algum hóspede
  /// manda mensagem nova, mesmo com o staff em outra seção do portal.
  Future<void> _loadUnreadMessagesCount() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;
    try {
      final count = await _staysRepository.getUnreadMessagesCount(hotelId: widget.session.hotelId, token: token);
      if (!mounted) return;
      if (_unreadMessagesCountSeeded && count > _unreadMessagesCount) {
        playNewOrderSound();
        BrowserNotifications.show(title: 'Nova mensagem de hóspede', body: 'Confira em Quartos.');
      }
      setState(() {
        _unreadMessagesCount = count;
        _unreadMessagesCountSeeded = true;
      });
    } on StateError {
      // Badge não é crítico — falha silenciosa (ex: sem conexão).
    }
  }

  /// Sem endpoint dedicado de contagem (thread única por hotel, volume
  /// baixo) — conta client-side a partir da lista de mensagens já
  /// carregada pra alimentar o badge de "Suporte".
  Future<void> _loadUnreadSupportCount() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) return;
    try {
      final messages = await _supportRepository.listMessages(hotelId: widget.session.hotelId, token: token);
      if (!mounted) return;
      final unread = messages.where((message) => message.isFromPlatform && !message.readByHotel).length;
      setState(() => _unreadSupportCount = unread);
    } on StateError {
      // Badge não é crítico — falha silenciosa (ex: sem conexão).
    }
  }

  void _notifyNewOrders(List<Order> newOrders) {
    playNewOrderSound();
    final first = newOrders.first;
    final title = newOrders.length == 1 ? 'Novo pedido' : '${newOrders.length} novos pedidos';
    final body = newOrders.length == 1
        ? '${first.itemName} · ${first.guestName} · Quarto ${first.guestRoomNumber}'
        : 'O mais recente: ${first.itemName} · Quarto ${first.guestRoomNumber}';
    BrowserNotifications.show(title: title, body: body);
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus status) async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _ordersError = 'Sessão expirada — saia e entre novamente.');
      return;
    }
    try {
      await _ordersRepository.updateStatus(hotelId: widget.session.hotelId, orderId: order.id, token: token, status: status);
      await _loadOrders(silent: true);
    } on StateError catch (error) {
      setState(() => _ordersError = error.message);
    }
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
            badgeCounts: {
              _kPedidosIndex: _pendingOrderCount,
              _kQuartosIndex: _unreadMessagesCount,
              _kSuporteIndex: _unreadSupportCount,
            },
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
                      _kClientesIndex => CustomersPage(session: widget.session, authRepository: widget.authRepository),
                      _kQuartosIndex => RoomsPage(session: widget.session, authRepository: widget.authRepository),
                      _kPedidosIndex => OrdersPage(
                          isLoading: _ordersLoading,
                          errorMessage: _ordersError,
                          orders: _orders,
                          onStatusChange: (pair) => _updateOrderStatus(pair.$1, pair.$2),
                        ),
                      _kSuporteIndex => SupportPage(session: widget.session, authRepository: widget.authRepository),
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
