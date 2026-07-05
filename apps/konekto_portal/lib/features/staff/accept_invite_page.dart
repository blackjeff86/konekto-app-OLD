import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_gate.dart';
import 'package:konekto_portal/data/staff_invite_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Tela de cadastro pra quem recebeu um link de convite (`?invite=<code>`
/// na URL do portal) — acessível sem login, roteada direto de `main.dart`.
/// Em caso de sucesso, o backend já cria a conta e devolve um token válido
/// (mesmo formato de `/api/auth/login`), então loga automaticamente e
/// substitui essa tela por [StaffGate], que leva ao dashboard.
class AcceptInvitePage extends StatefulWidget {
  final String inviteCode;
  final AuthRepository authRepository;

  const AcceptInvitePage({super.key, required this.inviteCode, required this.authRepository});

  @override
  State<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends State<AcceptInvitePage> {
  final _repository = StaffInviteRepository();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await _repository.acceptInvite(
        code: widget.inviteCode,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await widget.authRepository.signInWithToken(result['token'] as String);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => StaffGate(authRepository: widget.authRepository)),
      );
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektoBrand.ink,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: KonektoMark(size: 48)),
                const SizedBox(height: 24),
                Text('Você foi convidado', style: KonektoBrand.display(fontSize: 20), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  'Crie sua conta pra acessar o portal como recepção.',
                  style: KonektoBrand.body(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1ADC2626),
                      border: Border.all(color: const Color(0x4DDC2626)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
                  ),
                  const SizedBox(height: 16),
                ],
                _InviteField(label: 'Nome', controller: _nameController),
                const SizedBox(height: 14),
                _InviteField(label: 'E-mail', controller: _emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _InviteField(label: 'Senha (mín. 8 caracteres)', controller: _passwordController, obscureText: true),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KonektoBrand.gold,
                      foregroundColor: KonektoBrand.ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: KonektoBrand.ink),
                          )
                        : Text('Criar conta', style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _InviteField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KonektoBrand.borderStrong, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KonektoBrand.gold, width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
