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
import 'package:konekto/l10n/locale_controller.dart';
import 'package:konekto/theme/guest_app_theme.dart';
import 'package:konekto/theme/guest_infra.dart';
import 'package:konekto/widgets/tenant_image.dart';

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
  int _unreadMessagesCount = 0;
  int _unseenOrdersCount = 0;

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
    return GuestAppTheme.fromTenantConfig(tenantConfigMap);
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
    return switch (kGuestNavItems[index].route) {
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
      'profile' => ProfilePage(
          theme: theme,
          guestName: widget.guestName,
          roomNumber: widget.guestRoomNumber,
          onEndSession: () => Navigator.of(context).popUntil((route) => route.isFirst),
          onOpenStayBill: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StayBillPage(theme: theme))),
        ),
      _ => Center(child: Text(l10n.screenNotFound)),
    };
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
                  children: List.generate(kGuestNavItems.length, (index) {
                    final item = kGuestNavItems[index];
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.tokens.screenPadding),
          child: switch (theme.infra) {
            GuestInfra.verdePousada => _buildVerdeContent(context),
            GuestInfra.casaMarechal => _buildCasaMarechalContent(context),
            GuestInfra.amaraBay => _buildAmaraContent(context),
          },
        ),
      ),
    );
  }

  Widget _headerIcon(BuildContext context, {required IconData icon, required VoidCallback onTap, int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: theme.accent),
          ),
          if (badgeCount > 0) Positioned(top: -2, right: -2, child: _NotificationCountBadge(count: badgeCount, theme: theme)),
        ],
      ),
    );
  }

  void _openNotices(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoticesPage(tenantConfig: tenantConfig, theme: theme)),
    );
    onNoticesReturned();
  }

  void _openMyOrders(BuildContext context) async {
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

  /// Logo do hotel (`hotelInfo.logoUrl`) — cai num ícone genérico quando o
  /// hotel ainda não configurou um logo no portal.
  Widget _buildLogo({required double size, required BorderRadius borderRadius, required IconData fallbackIcon, bool filled = true}) {
    final logoUrl = theme.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: filled ? theme.accentSoft : null,
        border: filled ? null : Border.all(color: theme.borderColor),
        borderRadius: borderRadius,
      ),
      child: hasLogo
          ? TenantImage(imageUrl: logoUrl, hotelId: tenantId, fit: BoxFit.contain, width: size, height: size)
          : Icon(fallbackIcon, color: theme.accent, size: size * 0.5),
    );
  }

  /// Amara Bay: header centralizado, hero com carrossel de fotos, texto de
  /// boas-vindas genérico, cartão de quarto/wifi elevado, grade 2x2 de
  /// acesso rápido.
  Widget _buildAmaraContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            _buildLogo(size: 44, borderRadius: BorderRadius.circular(12), fallbackIcon: Icons.door_front_door_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(theme.hotelName, style: theme.headline()),
                  Text(
                    l10n.amaraResortTag,
                    style: theme.body(fontSize: 10, fontWeight: FontWeight.w600, color: theme.mutedColor).copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _headerIcon(
                context,
                icon: Icons.notifications_outlined,
                onTap: () => _openNotices(context),
                badgeCount: notificationCount,
              ),
            ),
            _headerIcon(context, icon: Icons.person_outline, onTap: () {}),
          ],
        ),
        const SizedBox(height: 16),
        if (theme.promoImages.isNotEmpty) ...[
          ImageCarousel(imageUrls: theme.promoImages, height: theme.carouselHeight, hotelId: tenantId, theme: theme),
          const SizedBox(height: 20),
        ],
        Text(l10n.homeWelcomeName(userName), style: theme.headline()),
        const SizedBox(height: 4),
        Text(l10n.homeCheckinMessage, style: theme.body(color: theme.mutedColor)),
        const SizedBox(height: 24),
        ExpandableCard(
          roomNumber: roomNumber,
          wifiNetworkName: wifiNetworkName,
          wifiPassword: wifiPassword,
          theme: theme,
        ),
        const SizedBox(height: 24),
        Text(l10n.homeOurServices, style: theme.headline(fontSize: 18)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickTile(title: l10n.quickTileServices, icon: Icons.room_service_outlined, theme: theme, onTap: onNavigateToServices),
            _QuickTile(title: l10n.quickTileHistory, icon: Icons.history, theme: theme, onTap: () => _openMyOrders(context)),
            _QuickTile(title: l10n.quickTileMap, icon: Icons.map_outlined, theme: theme, onTap: () => _openHotelInfo(context)),
            _QuickTile(title: l10n.quickTileNotices, icon: Icons.campaign_outlined, theme: theme, onTap: () => _openNotices(context)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Verde Pousada: editorial, sem hero/carrossel — header simples,
  /// saudação com o nome do hóspede em destaque, acordeão fino de
  /// wifi/quarto, serviços em lista vertical (não grade).
  Widget _buildVerdeContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            _buildLogo(
              size: 40,
              borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
              fallbackIcon: Icons.layers_outlined,
              filled: false,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(theme.hotelName, style: theme.headline(fontSize: 17))),
            GestureDetector(
              onTap: () => _openNotices(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_outlined, color: theme.mutedColor),
                  if (notificationCount > 0) Positioned(top: -2, right: -2, child: _NotificationCountBadge(count: notificationCount, theme: theme)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.person_outline, color: theme.mutedColor),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          l10n.homeWelcomeBack,
          style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: theme.mutedColor).copyWith(letterSpacing: 1.1),
        ),
        const SizedBox(height: 6),
        Text(userName, style: theme.headline(fontSize: 28)),
        const SizedBox(height: 6),
        Text(l10n.homeCheckinRoom(roomNumber), style: theme.body(color: theme.mutedColor)),
        const SizedBox(height: 36),
        ExpandableCard(
          title: l10n.roomWifiDetailsShort,
          icon: Icons.home_outlined,
          flat: true,
          roomNumber: roomNumber,
          wifiNetworkName: wifiNetworkName,
          wifiPassword: wifiPassword,
          theme: theme,
        ),
        const SizedBox(height: 32),
        Text(l10n.homeOurServices, style: theme.headline(fontSize: 18)),
        const SizedBox(height: 8),
        _VerdeServiceRow(title: l10n.quickTileServices, icon: Icons.room_service_outlined, theme: theme, onTap: onNavigateToServices),
        _VerdeServiceRow(title: l10n.quickTileHistory, icon: Icons.history, theme: theme, onTap: () => _openMyOrders(context)),
        _VerdeServiceRow(title: l10n.quickTileMap, icon: Icons.map_outlined, theme: theme, onTap: () => _openHotelInfo(context)),
        _VerdeServiceRow(title: l10n.quickTileNotices, icon: Icons.campaign_outlined, theme: theme, onTap: () => _openNotices(context), isLast: true),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Casa Marechal: heranca classica — badge de quarto centralizado, saudacao
  /// serifada centralizada com friso dourado, grade de acessos com bordas
  /// finas (sem sombra/preenchimento, ao contrario da Amara Bay), carrossel
  /// de fotos em cartoes emoldurados ("Destaques da Casa" — reaproveita as
  /// mesmas promoImages configuradas pelo hotel, sem inventar um catalogo de
  /// "experiencias" que o backend nao modela) e um banner de destaque solido
  /// levando pra Servicos (no lugar da recomendacao fixa do concierge do
  /// mockup, que nao tem dado real por tras).
  Widget _buildCasaMarechalContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            _buildLogo(size: 44, borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius), fallbackIcon: Icons.villa_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(theme.hotelName, style: theme.headline()),
                  Text(
                    l10n.casaMarechalTag,
                    style: theme.body(fontSize: 10, fontWeight: FontWeight.w600, color: theme.mutedColor).copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _headerIcon(
                context,
                icon: Icons.notifications_outlined,
                onTap: () => _openNotices(context),
                badgeCount: notificationCount,
              ),
            ),
            _headerIcon(context, icon: Icons.person_outline, onTap: () {}),
          ],
        ),
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(theme.tokens.pillRadius)),
                child: Text(
                  l10n.roomNumberLabel(roomNumber).toUpperCase(),
                  style: theme.body(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white).copyWith(letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              Text(l10n.homeWelcomeName(userName), textAlign: TextAlign.center, style: theme.headline(fontSize: 26)),
              const SizedBox(height: 16),
              Container(width: 64, height: 1, color: theme.accent.withValues(alpha: 0.35)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CasaQuickAction(title: l10n.quickTileServices, icon: Icons.room_service_outlined, theme: theme, onTap: onNavigateToServices),
            _CasaQuickAction(title: l10n.quickTileHistory, icon: Icons.history, theme: theme, onTap: () => _openMyOrders(context)),
            _CasaQuickAction(title: l10n.quickTileMap, icon: Icons.map_outlined, theme: theme, onTap: () => _openHotelInfo(context)),
            _CasaQuickAction(title: l10n.quickTileNotices, icon: Icons.campaign_outlined, theme: theme, onTap: () => _openNotices(context)),
          ],
        ),
        const SizedBox(height: 28),
        ExpandableCard(
          roomNumber: roomNumber,
          wifiNetworkName: wifiNetworkName,
          wifiPassword: wifiPassword,
          theme: theme,
          icon: Icons.villa_outlined,
        ),
        if (theme.promoImages.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(l10n.casaFeaturedTitle, style: theme.headline(fontSize: 19)),
          const SizedBox(height: 4),
          Text(l10n.casaFeaturedSubtitle, style: theme.body(fontSize: 12.5, color: theme.mutedColor, fontStyle: FontStyle.italic)),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: theme.promoImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _CasaExperienceCard(
                imageUrl: theme.promoImages[index],
                hotelId: tenantId,
                theme: theme,
                badge: index == 0 ? l10n.casaMarechalTag : null,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _CasaConciergeBanner(
          theme: theme,
          onTap: onNavigateToServices,
          title: l10n.casaConciergeTitle,
          subtitle: l10n.casaConciergeSubtitle,
          cta: l10n.casaConciergeCta,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Pílula vermelha com a quantidade de notificações (mensagens da recepção
/// não lidas + pedidos com status não visto) — "9+" acima de 9 pra não
/// estourar o layout do sino.
class _NotificationCountBadge extends StatelessWidget {
  final int count;
  final GuestAppTheme theme;

  const _NotificationCountBadge({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: count > 9 ? BorderRadius.circular(8) : null,
        color: Colors.red.shade600,
        border: Border.all(color: theme.bg, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1),
      ),
    );
  }
}

class _VerdeServiceRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final GuestAppTheme theme;
  final VoidCallback onTap;
  final bool isLast;

  const _VerdeServiceRow({required this.title, required this.icon, required this.theme, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: theme.borderColor))),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.accent),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: theme.body(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: theme.mutedColor),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _QuickTile({required this.title, required this.icon, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - theme.tokens.screenPadding * 2 - 12) / 2,
        height: 116,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBg,
          border: Border.all(color: theme.borderColor),
          borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
          boxShadow: theme.tokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
              child: Icon(icon, color: theme.accent, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.headline(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Acesso rapido da Casa Marechal: contorno fino sem preenchimento/sombra
/// (ao contrario do `_QuickTile` da Amara Bay), rotulo em caixa alta —
/// reflete o `borderRadius` quase reto e a paleta esmeralda/dourada do
/// design system do Stitch.
class _CasaQuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _CasaQuickAction({required this.title, required this.icon, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - theme.tokens.screenPadding * 2 - 12) / 2,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(theme.tokens.iconTileRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accent, size: 26),
            const SizedBox(height: 10),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: theme.textColor).copyWith(letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartao emoldurado do carrossel "Destaques da Casa" — reaproveita as
/// mesmas `promoImages` que a Amara Bay usa no hero cheio de tela, so que em
/// cartoes menores com moldura fina (ao inves de um carrossel full-bleed),
/// pra bater com a estetica de galeria do mockup Casa Marechal do Stitch.
class _CasaExperienceCard extends StatelessWidget {
  final String imageUrl;
  final String hotelId;
  final GuestAppTheme theme;
  final String? badge;

  const _CasaExperienceCard({required this.imageUrl, required this.hotelId, required this.theme, this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: theme.accent.withValues(alpha: 0.25))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TenantImage(imageUrl: imageUrl, hotelId: hotelId, fit: BoxFit.cover),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: theme.accent,
                  child: Text(
                    badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Banner solido levando pra Servicos — substitui a "recomendacao fixa do
/// concierge" do mockup (evento datado sem contrapartida real no backend)
/// por uma chamada honesta pra funcionalidade que de fato existe.
class _CasaConciergeBanner extends StatelessWidget {
  final GuestAppTheme theme;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String cta;

  const _CasaConciergeBanner({
    required this.theme,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.headline(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 10),
            Text(subtitle, style: theme.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cta.toUpperCase(),
                  style: theme.body(fontSize: 12, fontWeight: FontWeight.w700, color: theme.accentSoft).copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: theme.accentSoft),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final GuestAppTheme theme;
  final String? title;
  final IconData icon;

  /// Verde Pousada usa uma versão "achatada" (sem borda/sombra, fundo
  /// levemente tintado) — mais próxima de uma linha de acordeão editorial
  /// do que um cartão elevado (o estilo padrão, usado pela Amara Bay).
  final bool flat;

  const ExpandableCard({
    super.key,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.theme,
    this.title,
    this.icon = Icons.door_front_door_outlined,
    this.flat = false,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  GuestAppTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.title ?? l10n.roomWifiDetails;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.flat ? 4 : 16),
      decoration: BoxDecoration(
        color: widget.flat ? theme.accentSoft : theme.cardBg,
        borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
        border: widget.flat ? null : Border.all(color: theme.borderColor),
        boxShadow: widget.flat ? null : theme.tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: widget.flat ? 12 : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!widget.flat) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
                          child: Icon(widget.icon, color: theme.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        Icon(widget.icon, color: theme.accent, size: 18),
                        const SizedBox(width: 10),
                      ],
                      Text(title, style: theme.headline(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down, color: theme.accent),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Divider(color: theme.borderColor),
            const SizedBox(height: 16),
            _buildDetailRow(icon: Icons.person_pin, text: l10n.roomNumberLabel(widget.roomNumber)),
            const SizedBox(height: 12),
            _buildDetailRow(icon: Icons.wifi, text: l10n.wifiNetworkLabel(widget.wifiNetworkName)),
            const SizedBox(height: 12),
            _buildDetailRow(icon: Icons.lock, text: l10n.wifiPasswordLabel(widget.wifiPassword)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: theme.accent),
        const SizedBox(width: 8),
        Text(text, style: theme.body(color: theme.mutedColor)),
      ],
    );
  }
}

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final String hotelId;
  final GuestAppTheme theme;

  const ImageCarousel({
    super.key,
    required this.imageUrls,
    required this.height,
    required this.hotelId,
    required this.theme,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.theme.tokens.heroRadius;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return TenantImage(
                  imageUrl: widget.imageUrls[index],
                  hotelId: widget.hotelId,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                );
              },
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imageUrls.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final GuestAppTheme theme;
  final String guestName;
  final String roomNumber;
  final VoidCallback? onEndSession;
  final VoidCallback? onOpenStayBill;

  const ProfilePage({
    super.key,
    required this.theme,
    required this.guestName,
    required this.roomNumber,
    this.onEndSession,
    this.onOpenStayBill,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String initials = guestName.trim().isNotEmpty
        ? guestName.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase()
        : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent,
                  boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Text(initials, style: theme.headline(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(guestName, textAlign: TextAlign.center, style: theme.headline(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(theme.hotelName, textAlign: TextAlign.center, style: theme.body(color: theme.mutedColor, fontSize: 14)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                boxShadow: theme.tokens.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
                    child: Icon(Icons.meeting_room_outlined, color: theme.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.profileRoom, style: theme.body(color: theme.mutedColor, fontSize: 13)),
                      Text(roomNumber, style: theme.headline(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onOpenStayBill,
              borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                  boxShadow: theme.tokens.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
                      child: Icon(Icons.receipt_long_outlined, color: theme.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(l10n.myAccountTile, style: theme.body(fontWeight: FontWeight.w600))),
                    Icon(Icons.chevron_right_rounded, color: theme.mutedColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                boxShadow: theme.tokens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profileLanguage, style: theme.body(color: theme.mutedColor, fontSize: 13)),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<Locale>(
                    valueListenable: LocaleController.instance.locale,
                    builder: (context, currentLocale, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _LanguageOption(
                              label: 'Português',
                              selected: currentLocale.languageCode == 'pt',
                              theme: theme,
                              onTap: () => LocaleController.instance.setLocale(const Locale('pt')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LanguageOption(
                              label: 'English',
                              selected: currentLocale.languageCode == 'en',
                              theme: theme,
                              onTap: () => LocaleController.instance.setLocale(const Locale('en')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LanguageOption(
                              label: 'Español',
                              selected: currentLocale.languageCode == 'es',
                              theme: theme,
                              onTap: () => LocaleController.instance.setLocale(const Locale('es')),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (onEndSession != null)
              OutlinedButton.icon(
                onPressed: onEndSession,
                icon: Icon(Icons.logout_rounded, color: theme.accent),
                label: Text(l10n.profileEndSession, style: theme.body(color: theme.accent, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.accent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.accentSoft,
          borderRadius: BorderRadius.circular(theme.tokens.pillRadius),
          border: selected ? null : Border.all(color: theme.borderColor),
        ),
        child: Text(
          label,
          style: theme.body(
            color: selected ? Colors.white : theme.mutedColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
