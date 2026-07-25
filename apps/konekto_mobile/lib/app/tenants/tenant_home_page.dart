import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/bookings_page.dart';
import 'package:konekto/app/tenants/hotel_info_page.dart';
import 'package:konekto/app/tenants/my_orders_page.dart';
import 'package:konekto/app/tenants/notices_page.dart';
import 'package:konekto/app/tenants/services_page.dart';
import 'package:konekto/app/tenants/stay_bill_page.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/messages_repository.dart';
import 'package:konekto/data/orders_repository.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/modules/module_catalog_repository.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/modules/module_engine.dart';
import 'package:konekto/modules/screens/loyalty_wallet_dispatch.dart';
import 'package:konekto/templates/guest_template_registry.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/widgets/profile_page.dart';
import 'package:konekto/theme/guest_app_theme.dart';

String navItemLabel(AppLocalizations l10n, String route) => switch (route) {
      'home' => l10n.navHome,
      'services' => l10n.navServices,
      'bookings' => l10n.navBookings,
      'profile' => l10n.navProfile,
      _ => route,
    };

class TenantHomePage extends StatefulWidget {
  final String tenantId;

  /// Identidade real do hóspede — sempre vem do `GuestClaimRepository`
  /// (código individual gerado pela recepção); não existe mais um fluxo
  /// de acesso sem hóspede identificado.
  final String guestName;
  final String guestRoomNumber;
  final String? wifiNetworkName;
  final String? wifiPassword;

  const TenantHomePage({
    super.key,
    required this.tenantId,
    required this.guestName,
    required this.guestRoomNumber,
    this.wifiNetworkName,
    this.wifiPassword,
  });

  @override
  State<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends State<TenantHomePage> {
  int _selectedIndex = 0;
  late Future<GuestAppTheme> _themeFuture;
  Map<String, dynamic>? _tenantConfig;
  final TenantRepository _repository = createTenantRepository();
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final MessagesRepository _messagesRepository = MessagesRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  final ModuleCatalogRepository _moduleCatalogRepository = ModuleCatalogRepository();
  int _unreadMessagesCount = 0;
  int _unseenOrdersCount = 0;
  // Module Engine (Fase 6) — nav dinâmica por hotel, a partir de
  // `tenantConfig['enabledModules']`. Começa com o fallback fixo de sempre
  // e só troca depois que `_loadTheme()` resolve; hotel sem módulos
  // configurados no backend (ou catálogo indisponível) nunca fica com nav
  // vazia.
  List<GuestNavItem> _navItems = kGuestNavItems;

  int get _notificationCount => _unreadMessagesCount + _unseenOrdersCount;

  @override
  void initState() {
    super.initState();
    _themeFuture = _loadTheme();
    _refreshUnreadCount();
  }

  Future<GuestAppTheme> _loadTheme() async {
    final tenantConfigMap = await _repository.getTenantConfig(widget.tenantId);
    _tenantConfig = tenantConfigMap;
    await _resolveNavItems(tenantConfigMap);
    return GuestAppTheme.fromTenantConfig(tenantConfigMap);
  }

  Future<void> _resolveNavItems(Map<String, dynamic> tenantConfigMap) async {
    try {
      final catalog = await _moduleCatalogRepository.getCatalog();
      final resolvedModules = resolvedModulesFromTenantConfig(tenantConfigMap);
      _navItems = ModuleEngine.resolveNavItems(enabledModules: resolvedModules, catalog: catalog);
    } on StateError {
      // Catálogo indisponível (sem rede, backend fora do ar): mantém o
      // fallback fixo já setado — nunca deixa a nav vazia/quebrada.
    }
  }

  /// Soma mensagens não lidas da recepção + pedidos com mudança de status
  /// ainda não vista — os dois alimentam o mesmo número no sino da Home.
  Future<void> _refreshUnreadCount() async {
    final token = await _guestClaimRepository.getStoredToken();
    if (token == null) return;
    try {
      final messagesCount = await _messagesRepository.getUnreadCount(token: token);
      if (mounted) setState(() => _unreadMessagesCount = messagesCount);
    } on StateError {
      // Badge não é crítico — falha silenciosa (ex: sem conexão).
    }
    try {
      final ordersCount = await _ordersRepository.getUnseenStatusCount(token: token);
      if (mounted) setState(() => _unseenOrdersCount = ordersCount);
    } on StateError {
      // Badge não é crítico — falha silenciosa (ex: sem conexão).
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _getWidgetForIndex(int index, GuestAppTheme theme, AppLocalizations l10n) {
    final tenantConfig = _tenantConfig!;
    return switch (_navItems[index].route) {
      'home' => TenantHomeBody(
          tenantId: widget.tenantId,
          userName: widget.guestName,
          roomNumber: widget.guestRoomNumber,
          wifiNetworkName: widget.wifiNetworkName ?? l10n.notAvailable,
          wifiPassword: widget.wifiPassword ?? l10n.notAvailable,
          tenantConfig: tenantConfig,
          theme: theme,
          onNavigateToServices: () => _onItemTapped(1),
          notificationCount: _notificationCount,
          onNoticesReturned: _refreshUnreadCount,
          onOrdersReturned: _refreshUnreadCount,
        ),
      'services' => ServicesPage(tenantConfig: tenantConfig, theme: theme),
      'bookings' => BookingsPage(tenantConfig: tenantConfig, theme: theme, onExploreServices: () => _onItemTapped(1)),
      'profile' => _buildProfilePage(tenantConfig, theme),
      _ => Center(child: Text(l10n.screenNotFound)),
    };
  }

  /// Loyalty/Wallet (Fase 11) — cada tela ainda é desenhada pra combinar
  /// com UM template (Elite/Pulse/Horizon); Aura/Bosque não têm tela
  /// própria ainda, então `resolveLoyaltyScreen`/`resolveWalletScreen`
  /// devolvem `null` e a linha correspondente simplesmente não aparece no
  /// Perfil (ver `ProfilePage.onOpenLoyalty`/`onOpenWallet`).
  Widget _buildProfilePage(Map<String, dynamic> tenantConfig, GuestAppTheme theme) {
    final templateId = guestTemplateIdFromString(tenantConfig['template'] as String?) ?? GuestTemplateId.aura;
    final features = GuestFeatures.fromTenantConfig(tenantConfig);
    final loyaltyScreen = resolveLoyaltyScreen(templateId, features);
    final walletScreen = resolveWalletScreen(templateId, features);

    return ProfilePage(
      theme: theme,
      guestName: widget.guestName,
      roomNumber: widget.guestRoomNumber,
      onEndSession: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onOpenStayBill: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StayBillPage(theme: theme))),
      onOpenLoyalty: loyaltyScreen == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => loyaltyScreen)),
      onOpenWallet: walletScreen == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => walletScreen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GuestAppTheme>(
      future: _themeFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFFF8),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text(l10n.errorLoadingData(snapshot.error.toString()))));
        }

        final theme = snapshot.data!;

        return Scaffold(
          backgroundColor: theme.bg,
          body: _getWidgetForIndex(_selectedIndex, theme, l10n),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.tokens.bottomNavBg,
              border: Border(top: BorderSide(color: theme.tokens.bottomNavBorder)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final selected = _selectedIndex == index;
                    final color = selected ? theme.accent : theme.tokens.navInactive;
                    return Expanded(
                      child: InkWell(
                        onTap: () => _onItemTapped(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, color: color, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              navItemLabel(l10n, item.route),
                              style: theme.body(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Orquestra a Home do hóspede: monta os parâmetros/callbacks comuns
/// (abrir avisos/pedidos/info do hotel) e delega o layout em si pro widget
/// de template correto via `guest_template_registry.dart` — o conteúdo
/// visual de cada template vive em `lib/templates/<template>/home_screen.dart`,
/// não aqui.
class TenantHomeBody extends StatelessWidget {
  final String tenantId;
  final String userName;
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;
  final VoidCallback onNavigateToServices;
  final int notificationCount;
  final VoidCallback onNoticesReturned;
  final VoidCallback onOrdersReturned;

  const TenantHomeBody({
    super.key,
    required this.tenantId,
    required this.userName,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.tenantConfig,
    required this.theme,
    required this.onNavigateToServices,
    this.notificationCount = 0,
    required this.onNoticesReturned,
    required this.onOrdersReturned,
  });

  Future<void> _openNotices(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoticesPage(tenantConfig: tenantConfig, theme: theme)),
    );
    onNoticesReturned();
  }

  Future<void> _openMyOrders(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyOrdersPage(tenantConfig: tenantConfig, theme: theme)),
    );
    onOrdersReturned();
  }

  void _openHotelInfo(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelInfoPage(
            roomNumber: roomNumber,
            wifiNetworkName: wifiNetworkName,
            wifiPassword: wifiPassword,
            theme: theme,
          ),
        ),
      );

  /// White Label: a Home sempre usa um dos 5 templates novos
  /// (Aura/Bosque/Elite/Pulse/Horizon), conforme `tenantConfig['template']`
  /// — hotel sem esse campo setado (não deveria acontecer em produção,
  /// todo hotel novo já nasce com `template: aura`) cai no fallback Aura,
  /// nunca quebra por falta de dado. O sistema antigo de 5 infraestruturas
  /// visuais (Amara Bay/Verde Pousada/Casa Marechal/Konekto Clássico/
  /// Konekto Noturno) foi arquivado — ver `legacy-templates/` na raiz do
  /// projeto.
  @override
  Widget build(BuildContext context) {
    final templateId = guestTemplateIdFromString(tenantConfig['template'] as String?) ?? GuestTemplateId.aura;
    final templateParams = GuestTemplateContentParams(
      tenantId: tenantId,
      userName: userName,
      roomNumber: roomNumber,
      wifiNetworkName: wifiNetworkName,
      wifiPassword: wifiPassword,
      theme: guestTemplateThemes[templateId]!,
      notificationCount: notificationCount,
      onNavigateToServices: onNavigateToServices,
      onOpenNotices: _openNotices,
      onOpenMyOrders: _openMyOrders,
      onOpenHotelInfo: _openHotelInfo,
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.tokens.screenPadding),
          child: buildGuestTemplateHomeContent(templateId, templateParams),
        ),
      ),
    );
  }
}
