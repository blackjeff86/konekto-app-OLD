import 'package:flutter/material.dart';
import 'package:konekto_admin/auth/admin_gate.dart';
import 'package:konekto_admin/auth/auth_repository.dart';

void main() {
  runApp(const KonektoAdminApp());
}

class KonektoAdminApp extends StatelessWidget {
  const KonektoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    return MaterialApp(
      title: 'Konekto Admin',
      debugShowCheckedModeBanner: false,
      home: AdminGate(authRepository: authRepository),
    );
  }
}
