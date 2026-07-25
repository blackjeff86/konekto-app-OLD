import 'package:flutter/material.dart';
import 'package:konekto/layout/layout_variant.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/modules/module_icons.dart';

/// Layout Registry — separado do Module Registry (Fase 7): Module Registry
/// sabe COMO o módulo funciona (tela/permissões/ações); isto sabe as
/// VARIANTES de como ele pode aparecer como card/seção. Cada template
/// (Fase 9/11) pede a variante que combina com sua identidade visual, sem
/// nenhuma condicional de módulo dentro do template.
class LayoutRegistry {
  const LayoutRegistry._();

  static final Map<String, Map<String, LayoutVariant>> _variants = {};

  static void register(String moduleId, LayoutVariant variant) {
    _variants.putIfAbsent(moduleId, () => {})[variant.id] = variant;
  }

  static void registerAll(String moduleId, List<LayoutVariant> variants) {
    for (final variant in variants) {
      register(moduleId, variant);
    }
  }

  /// Resolve a variante pedida; sem registro específico pro módulo/
  /// variante, cai no card compacto genérico — nunca devolve null, nunca
  /// trava um template esperando uma variante que ainda não foi desenhada
  /// (ver `implemented: false` no Module Catalog).
  static LayoutVariant resolve(String moduleId, String variantId) {
    return _variants[moduleId]?[variantId] ?? LayoutVariant(id: variantId, builder: _genericCompactCard);
  }

  static bool hasVariant(String moduleId, String variantId) => _variants[moduleId]?.containsKey(variantId) ?? false;

  static Widget _genericCompactCard(BuildContext context, ModuleDefinition module) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(resolveModuleIcon(module.icon), size: 22, color: const Color(0xFF111827)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(module.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                Text(
                  module.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Só pra testes — evita que registros de um teste vazem pro próximo.
  static void resetForTesting() => _variants.clear();
}
