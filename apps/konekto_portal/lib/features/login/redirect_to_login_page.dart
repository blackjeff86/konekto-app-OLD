import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:konekto_portal/site_config.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Mostrada quando não há sessão válida. O portal não tem formulário de
/// login próprio — a única tela de login real é apps/konekto_site/login.html
/// (evita manter duas telas de login em paralelo). Redireciona
/// automaticamente assim que é montada.
class RedirectToLoginPage extends StatefulWidget {
  final String? errorCode;

  const RedirectToLoginPage({super.key, this.errorCode});

  @override
  State<RedirectToLoginPage> createState() => _RedirectToLoginPageState();
}

class _RedirectToLoginPageState extends State<RedirectToLoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    final uri = Uri.parse(siteLoginUrl);
    final target = widget.errorCode == null ? uri : uri.replace(queryParameters: {'error': widget.errorCode});
    web.window.location.href = target.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektoBrand.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: KonektoBrand.gold),
            const SizedBox(height: 16),
            Text('Redirecionando para o login...', style: KonektoBrand.body(color: KonektoBrand.slate)),
          ],
        ),
      ),
    );
  }
}
