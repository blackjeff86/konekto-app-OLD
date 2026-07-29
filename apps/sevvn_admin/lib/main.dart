import 'package:flutter/material.dart';
import 'package:sevvn_admin/auth/admin_gate.dart';
import 'package:sevvn_admin/auth/auth_repository.dart';

void main() {
  runApp(const SevvnAdminApp());
}

class SevvnAdminApp extends StatelessWidget {
  const SevvnAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    return MaterialApp(
      title: 'Sevvn Admin',
      debugShowCheckedModeBanner: false,
      home: AdminGate(authRepository: authRepository),
    );
  }
}

