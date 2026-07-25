import 'package:flutter/material.dart';
import 'package:konekto/navigation/presentation_mode.dart';

/// Contexto mínimo que todo módulo recebe pra se renderizar/agir — genérico
/// de propósito (não carrega nada específico de template/tela), cresce
/// conforme módulos reais precisarem (ver Fase 9/11).
class ModuleRenderContext {
  final String tenantId;
  final String? guestToken;
  final Map<String, dynamic> configuration;

  const ModuleRenderContext({required this.tenantId, this.guestToken, this.configuration = const {}});
}

/// Module Registry (lado Flutter) — o Module Catalog (backend) DESCREVE um
/// módulo; isto CONECTA ao código de verdade: a tela do módulo (quando
/// existe uma própria, ver `screenBuilder`), quais permissões o hóspede
/// precisa ter, e as ações que o módulo publica no Event Bus. Variantes
/// visuais de CARD pra Home vivem no Layout Registry (Fase 8) — isto aqui
/// não é sobre layout, é sobre função.
class ModuleRegistryEntry {
  final String moduleId;
  /// null = módulo não tem tela própria (só aparece como card/seção, ou
  /// ainda não foi implementado — ver `ModuleDefinition.implemented`).
  final Widget Function(BuildContext context, ModuleRenderContext ctx)? screenBuilder;
  /// Ex: `{'guestClaimed'}` — hóspede precisa estar identificado (token
  /// salvo) antes do Navigation Engine tentar abrir a tela.
  final Set<String> requiredPermissions;
  /// Nome da ação -> o que ela faz. Toda ação publica um evento no Event
  /// Bus ao rodar — nunca chama outro módulo diretamente.
  final Map<String, void Function(ModuleRenderContext ctx)> actions;
  final PresentationMode defaultPresentation;

  const ModuleRegistryEntry({
    required this.moduleId,
    this.screenBuilder,
    this.requiredPermissions = const {},
    this.actions = const {},
    this.defaultPresentation = PresentationMode.page,
  });
}

/// Registro vivo — populado conforme cada módulo ganha tela de verdade
/// (Fase 11 registra Loyalty/Wallet, hoje presos dentro de templates sem
/// rota). Regra de ouro: módulo novo = função/tela implementada +
/// registrada aqui + cadastrada no Catalog (backend). Nenhuma camada acima
/// (Module Engine, Home Layout Engine, Navigation Engine) muda.
final Map<String, ModuleRegistryEntry> moduleRegistry = {};

ModuleRegistryEntry? getModuleRegistryEntry(String moduleId) => moduleRegistry[moduleId];
