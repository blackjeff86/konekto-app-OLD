import 'package:flutter/material.dart';
import 'package:sevvn_admin/auth/auth_repository.dart';
import 'package:sevvn_admin/features/login/login_page.dart';
import 'package:sevvn_admin/features/shell/admin_shell.dart';
import 'package:sevvn_admin/theme/konekto_brand.dart';

/// Widget raiz do app: decide entre a tela de login ou o portal, a partir
/// de [AuthRepository.authState]. Único "roteador" do app (sem pacote de
/// rotas, mesmo padrão do konekto_portal).
class AdminGate extends StatefulWidget {
  final AuthRepository authRepository;

  const AdminGate({super.key, required this.authRepository});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
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
          AuthStatus.unauthenticated => LoginPage(authRepository: widget.authRepository),
          AuthStatus.authenticated => AdminShell(session: state.session!, authRepository: widget.authRepository),
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

