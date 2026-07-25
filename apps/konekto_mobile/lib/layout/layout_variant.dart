import 'package:flutter/material.dart';
import 'package:konekto/modules/module_definition.dart';

typedef LayoutVariantBuilder = Widget Function(BuildContext context, ModuleDefinition module);

/// Uma forma de desenhar um módulo — ex: `restaurant` pode ter variantes
/// `hero_card`/`compact_card`/`carousel_card`; `promotions` pode ter
/// `banner`/`grid`. O Home Layout Engine (Fase 9) pede a variante certa
/// por template, sem nenhuma condicional dentro do módulo em si.
class LayoutVariant {
  final String id;
  final LayoutVariantBuilder builder;

  const LayoutVariant({required this.id, required this.builder});
}
