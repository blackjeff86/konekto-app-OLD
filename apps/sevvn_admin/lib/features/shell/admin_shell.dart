import 'package:flutter/material.dart';
import 'package:sevvn_admin/auth/admin_session.dart';
import 'package:sevvn_admin/auth/auth_repository.dart';
import 'package:sevvn_admin/features/clients/clients_list_page.dart';
import 'package:sevvn_admin/features/dashboard/dashboard_page.dart';
import 'package:sevvn_admin/features/financeiro/financeiro_page.dart';
import 'package:sevvn_admin/features/shell/admin_sidebar.dart';
import 'package:sevvn_admin/features/support/support_inbox_page.dart';
import 'package:sevvn_admin/theme/konekto_brand.dart';

const int _kDashboardIndex = 0;
const int _kClientesIndex = 1;
const int _kSuporteIndex = 2;
const int _kFinanceiroIndex = 3;

const AdminSection _kDashboardSection = (
  icon: Icons.dashboard_outlined,
  title: 'Dashboard',
);
const AdminSection _kClientesSection = (
  icon: Icons.apartment_outlined,
  title: 'Clientes',
);
const AdminSection _kSuporteSection = (
  icon: Icons.support_agent_outlined,
  title: 'Suporte',
);
const AdminSection _kFinanceiroSection = (
  icon: Icons.payments_outlined,
  title: 'Financeiro',
);

const List<AdminSection> _kSections = [
  _kDashboardSection,
  _kClientesSection,
  _kSuporteSection,
  _kFinanceiroSection,
];

/// Casca de navegação do portal admin — sidebar vertical convencional
/// (mesmo padrão de `konekto_portal/features/dashboard/widgets/portal_sidebar.dart`),
/// com uma página dedicada por seção em vez de abas horizontais.
class AdminShell extends StatefulWidget {
  final AdminSession session;
  final AuthRepository authRepository;

  const AdminShell({super.key, required this.session, required this.authRepository});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = _kDashboardIndex;

  @override
  Widget build(BuildContext context) {
    final section = _kSections[_selectedIndex];
    return Scaffold(
      backgroundColor: KonektoBrand.ink,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSidebar(
            sections: _kSections,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
            session: widget.session,
            authRepository: widget.authRepository,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Breadcrumb(sectionTitle: section.title),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: switch (_selectedIndex) {
                      _kDashboardIndex => DashboardPage(authRepository: widget.authRepository),
                      _kClientesIndex => ClientsListPage(authRepository: widget.authRepository),
                      _kSuporteIndex => SupportInboxPage(authRepository: widget.authRepository),
                      _kFinanceiroIndex => FinanceiroPage(authRepository: widget.authRepository),
                      _ => const SizedBox.shrink(),
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
  final String sectionTitle;

  const _Breadcrumb({required this.sectionTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: KonektoBrand.borderStrong))),
      child: Text(
        sectionTitle,
        style: KonektoBrand.body(fontSize: 13, fontWeight: FontWeight.w700, color: KonektoBrand.cream),
      ),
    );
  }
}

