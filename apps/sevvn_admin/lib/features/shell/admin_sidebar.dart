import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sevvn_admin/auth/admin_session.dart';
import 'package:sevvn_admin/auth/auth_repository.dart';
import 'package:sevvn_admin/theme/konekto_brand.dart';

typedef AdminSection = ({IconData icon, String title});

/// Rail lateral do portal admin — mesma estrutura visual de
/// `konekto_portal/features/dashboard/widgets/portal_sidebar.dart`
/// (logo/wordmark no topo, indicador dourado no item ativo, conta ancorada
/// embaixo), duplicada aqui porque os dois apps não compartilham código.
class AdminSidebar extends StatelessWidget {
  final List<AdminSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AdminSession session;
  final AuthRepository authRepository;

  const AdminSidebar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
    required this.session,
    required this.authRepository,
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
                SvgPicture.asset('assets/logo/mini_logo.svg', width: 26, height: 26 * 1913 / 1405),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sevvn', style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w800, color: KonektoBrand.cream)),
                      Text('ADMIN CONSOLE', style: KonektoBrand.eyebrow(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: KonektoBrand.borderStrong),
          const SizedBox(height: 12),
          for (var i = 0; i < sections.length; i++)
            _NavItem(
              section: sections[i],
              isSelected: i == selectedIndex,
              onTap: () => onSelected(i),
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
  final AdminSection section;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.section, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(width: 2, height: 18, color: isSelected ? KonektoBrand.gold : Colors.transparent),
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
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AdminSession session;
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
                Text(session.email, overflow: TextOverflow.ellipsis, style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.goldLight)),
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

