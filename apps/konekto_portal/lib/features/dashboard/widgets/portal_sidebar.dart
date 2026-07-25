import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

typedef DashboardSection = ({IconData icon, String title, String description});

/// Rail lateral do portal — não é o NavigationRail padrão do Material: logo
/// e wordmark no topo, indicador de item ativo em traço dourado (não chip
/// preenchido), e a conta do staff ancorada embaixo, separada da navegação.
class PortalSidebar extends StatelessWidget {
  final List<DashboardSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final StaffSession session;
  final AuthRepository authRepository;

  /// Contador exibido como uma pastilha depois do título — indexado pela
  /// posição em [sections]. Índices ausentes ou com valor 0 não mostram
  /// nada (ex: pedidos pendentes na aba "Pedidos").
  final Map<int, int> badgeCounts;

  const PortalSidebar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
    required this.session,
    required this.authRepository,
    this.badgeCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: KonektoBrand.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                const KonektoMark(size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Konekto', style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w800, color: KonektoBrand.cream)),
                      Text('PORTAL DO HOTEL', style: KonektoBrand.eyebrow(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: KonektoBrand.borderStrong),
          const SizedBox(height: 12),
          for (var i = 0; i < sections.length; i++) _NavItem(
            section: sections[i],
            isSelected: i == selectedIndex,
            onTap: () => onSelected(i),
            badgeCount: badgeCounts[i] ?? 0,
          ),
          const Spacer(),
          const Divider(height: 1, color: KonektoBrand.borderStrong),
          _AccountRow(session: session, authRepository: authRepository),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DashboardSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({required this.section, required this.isSelected, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 18,
              color: isSelected ? KonektoBrand.gold : Colors.transparent,
            ),
            const SizedBox(width: 16),
            Icon(section.icon, size: 19, color: isSelected ? KonektoBrand.goldLight : KonektoBrand.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.title,
                style: KonektoBrand.body(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? KonektoBrand.cream : KonektoBrand.slate,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: KonektoBrand.gold, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: KonektoBrand.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const _AccountRow({required this.session, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.name,
                  overflow: TextOverflow.ellipsis,
                  style: KonektoBrand.body(fontSize: 12.5, fontWeight: FontWeight.w600, color: KonektoBrand.cream),
                ),
                Text(session.role.label, style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.goldLight)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout, size: 18, color: KonektoBrand.slate),
            onPressed: () => authRepository.signOut(),
          ),
        ],
      ),
    );
  }
}
