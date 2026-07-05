import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_gate.dart';
import 'package:konekto_portal/features/staff/accept_invite_page.dart';

void main() {
  runApp(const KonektoPortalApp());
}

class KonektoPortalApp extends StatelessWidget {
  const KonektoPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    // `?invite=<code>` é a única rota acessível sem login — sem pacote de
    // rotas no portal, então a checagem acontece aqui, antes do
    // `StaffGate` normal (consistente com apps/konekto_mobile/lib/routes.dart).
    final inviteCode = Uri.base.queryParameters['invite'];

    return MaterialApp(
      title: 'Konekto Portal',
      debugShowCheckedModeBanner: false,
      home: inviteCode != null
          ? AcceptInvitePage(inviteCode: inviteCode, authRepository: authRepository)
          : StaffGate(authRepository: authRepository),
    );
  }
}
