import 'package:flutter/material.dart';

/// Categoria de serviço de demonstração pro Diretório de Serviços dos
/// templates novos — mesmo critério do `GuestTemplateMenuItem`: dado
/// fictício só pra provar o visual, a Fase 4 troca pelas categorias reais
/// de `konekto/data/services_repository.dart`.
class GuestTemplateServiceCategory {
  final String name;
  final IconData icon;
  final bool featured;

  const GuestTemplateServiceCategory({required this.name, required this.icon, this.featured = false});
}
