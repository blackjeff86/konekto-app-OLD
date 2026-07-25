import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konekto_admin/theme/konekto_brand.dart';

/// Caixa de destaque pra mostrar um valor que o time Konekto precisa copiar
/// (ex: senha temporária do gerente recém-criado) — texto selecionável +
/// botão de copiar explícito. Duplicado (não compartilhado) a partir de
/// apps/konekto_portal/lib/widgets/copyable_code_box.dart.
class CopyableCodeBox extends StatelessWidget {
  final String value;
  final double fontSize;

  const CopyableCodeBox({super.key, required this.value, this.fontSize = 18});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(value, style: KonektoBrand.display(fontSize: fontSize, color: KonektoBrand.goldLight)),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_outlined, size: 18, color: KonektoBrand.slate),
            onPressed: () => _copy(context),
          ),
        ],
      ),
    );
  }
}
