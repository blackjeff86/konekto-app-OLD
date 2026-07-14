import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Caixa de destaque pra mostrar um código que o staff precisa copiar (ex:
/// código de acesso do hóspede) — texto selecionável (não só um `Text`
/// comum, que às vezes não deixa selecionar dependendo do contexto) +
/// botão de copiar explícito, pra nunca depender só da seleção manual.
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
            tooltip: 'Copiar código',
            icon: const Icon(Icons.copy_outlined, size: 18, color: KonektoBrand.slate),
            onPressed: () => _copy(context),
          ),
        ],
      ),
    );
  }
}
