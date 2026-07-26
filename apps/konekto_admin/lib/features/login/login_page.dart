import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web/web.dart' as web;
import 'package:konekto_admin/auth/auth_exceptions.dart';
import 'package:konekto_admin/auth/auth_repository.dart';
import 'package:konekto_admin/site_config.dart';
import 'package:konekto_admin/theme/konekto_brand.dart';

/// Paleta clara/rosa da marca — mesma usada em apps/konekto_site_next e
/// apps/konekto_portal_next (#FF2E88/#16181D/#F7F5F3/#FAFAF9). Escopada só
/// a esta tela: o resto do konekto_admin ainda está no tema escuro/dourado
/// de KonektoBrand, então os tokens não são reaproveitados daqui pra não
/// mudar nenhuma outra tela sem revisão visual.
class _LoginPalette {
  _LoginPalette._();

  static const Color bg = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF7F5F3);
  static const Color border = Color(0x1A16181D);
  static const Color borderStrong = Color(0x2916181D);
  static const Color ink = Color(0xFF16181D);
  static const Color muted = Color(0xFF5B5F68);
  static const Color mutedSoft = Color(0xFF85899A);
  static const Color primary = Color(0xFFFF2E88);
  static const Color onPrimary = Color(0xFFFFFFFF);
}

/// Login real (não existe uma tela compartilhada pra esse público — o
/// login.html do konekto_site é do staff de hotel). Mesmo tratamento
/// visual do cartão de login em apps/konekto_site_next ("Área do
/// hotel" -> "Bem-vindo(a) de volta" + campos com ícone), adaptado pro
/// público interno (sem CTA de "vire cliente", sem link de recuperação de
/// senha — só um punhado de contas, tratadas na mão pelo próprio time).
class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;

  const LoginPage({super.key, required this.authRepository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Preencha e-mail e senha.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.authRepository.login(email: email, password: password);
    } on InvalidCredentialsException {
      setState(() => _errorMessage = 'E-mail ou senha incorretos.');
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LoginPalette.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => web.window.location.href = siteHomeUrl,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/logo/mini_logo.svg', width: 26, height: 26 * 1913 / 1405),
                        const SizedBox(width: 10),
                        Text(
                          'Sevvn',
                          style: KonektoBrand.display(fontSize: 20, color: _LoginPalette.ink),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _LoginPalette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _LoginPalette.borderStrong),
                    boxShadow: [
                      BoxShadow(
                        color: _LoginPalette.ink.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Portal interno',
                        style: KonektoBrand.eyebrow(fontSize: 11, color: _LoginPalette.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bem-vindo(a) de volta',
                        style: KonektoBrand.display(fontSize: 24, color: _LoginPalette.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre para acompanhar os hotéis clientes, a saúde das integrações e o suporte.',
                        style: KonektoBrand.body(fontSize: 13.5, color: _LoginPalette.muted),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x14DC2626),
                            border: Border.all(color: const Color(0x40DC2626)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFB42318)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'E-mail',
                        style: KonektoBrand.body(fontSize: 12.5, color: _LoginPalette.muted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => _submit(),
                        style: KonektoBrand.body(fontSize: 14, color: _LoginPalette.ink),
                        decoration: _inputDecoration(hint: 'voce@konekto.app', icon: Icons.mail_outline),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Senha',
                        style: KonektoBrand.body(fontSize: 12.5, color: _LoginPalette.muted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        style: KonektoBrand.body(fontSize: 14, color: _LoginPalette.ink),
                        decoration: _inputDecoration(hint: '••••••••', icon: Icons.lock_outline),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(() => _rememberMe = value ?? true),
                                activeColor: _LoginPalette.primary,
                                side: const BorderSide(color: _LoginPalette.mutedSoft),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lembrar de mim',
                              style: KonektoBrand.body(fontSize: 12.5, color: _LoginPalette.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _LoginPalette.primary,
                            foregroundColor: _LoginPalette.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: _LoginPalette.onPrimary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Entrar no painel',
                                      style: KonektoBrand.body(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _LoginPalette.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 16, color: _LoginPalette.onPrimary),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: KonektoBrand.body(fontSize: 13.5, color: _LoginPalette.mutedSoft),
      prefixIcon: Icon(icon, size: 18, color: _LoginPalette.muted),
      filled: true,
      fillColor: _LoginPalette.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _LoginPalette.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _LoginPalette.primary, width: 1.6),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
