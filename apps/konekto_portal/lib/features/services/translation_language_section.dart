import 'package:flutter/material.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

class TranslationFieldController {
  final String label;
  final TextEditingController controller;

  const TranslationFieldController({
    required this.label,
    required this.controller,
  });
}

/// Bloco de campos de tradução pra um idioma (inglês OU espanhol), usado
/// dentro dos diálogos de edição de Serviço/Item. Cada campo já vem
/// pré-preenchido com a tradução atual (automática ou editada antes por
/// alguém do hotel) — deixar em branco significa "sem tradução própria
/// nesse campo/idioma", e o hóspede cai no texto em português.
class TranslationLanguageSection extends StatelessWidget {
  final String languageLabel;
  final List<TranslationFieldController> fields;
  final VoidCallback onAnyFieldChanged;

  const TranslationLanguageSection({
    super.key,
    required this.languageLabel,
    required this.fields,
    required this.onAnyFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageLabel,
          style: KonektoBrand.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KonektoBrand.slate,
          ),
        ),
        const SizedBox(height: 8),
        for (final field in fields) ...[
          TextField(
            controller: field.controller,
            onChanged: (_) => onAnyFieldChanged(),
            style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
            decoration: InputDecoration(
              labelText: field.label,
              labelStyle: KonektoBrand.body(
                fontSize: 11.5,
                color: KonektoBrand.slateSoft,
              ),
              isDense: true,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: KonektoBrand.borderStrong),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: KonektoBrand.gold),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
