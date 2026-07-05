import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/features/dashboard/dashboard_page.dart';
import 'package:konekto_portal/features/login/redirect_to_login_page.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Widget raiz do app: decide entre redirecionar pro login (site) ou
/// mostrar o DashboardPage, a partir de [AuthRepository.authState]. É o
/// único "roteador" do portal — sem pacote de rotas, consistente com
/// apps/konekto_mobile/lib/routes.dart.
///
/// Chama `restoreSession()` uma vez ao montar (consome token vindo da URL
/// ou rehidrata um token salvo).
class StaffGate extends StatefulWidget {
  final AuthRepository authRepository;

  const StaffGate({super.key, required this.authRepository});

  @override
  State<StaffGate> createState() => _StaffGateState();
}

class _StaffGateState extends State<StaffGate> {
  @override
  void initState() {
    super.initState();
    widget.authRepository.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: widget.authRepository.authState,
      builder: (context, state, _) {
        return switch (state.status) {
          AuthStatus.unknown => const _SplashLoading(),
          AuthStatus.unauthenticated => RedirectToLoginPage(errorCode: state.errorCode),
          AuthStatus.authenticated => DashboardPage(session: state.session!, authRepository: widget.authRepository),
        };
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: KonektoBrand.ink,
      body: Center(child: CircularProgressIndicator(color: KonektoBrand.gold)),
    );
  }
}
