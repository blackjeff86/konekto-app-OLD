import 'package:flutter/material.dart';
import 'package:konekto/modules/module_registry.dart';
import 'package:konekto/navigation/presentation_mode.dart';

/// Navigation Engine — resolve COMO abrir a tela de um módulo (página,
/// modal, bottom sheet, wizard) a partir só do `screenId` (identificador
/// lógico do Module Catalog) — o módulo em si nunca conhece rota nenhuma.
/// Troca o presentation mode de um módulo não exige tocar nele, só no
/// Module Registry (`defaultPresentation`) ou no `overrideMode` de quem
/// chama `present`.
class NavigationEngine {
  const NavigationEngine._();

  /// No-op seguro (não navega, não lança) quando o módulo não está
  /// registrado ou não tem `screenBuilder` — nunca deixa o app crashar por
  /// um módulo do catálogo sem tela ainda (`implemented: false`).
  static Future<void> present(
    BuildContext context, {
    required String screenId,
    required ModuleRenderContext moduleContext,
    PresentationMode? overrideMode,
  }) async {
    final entry = moduleRegistry[screenId];
    final builder = entry?.screenBuilder;
    if (entry == null || builder == null) return;

    final mode = overrideMode ?? entry.defaultPresentation;
    switch (mode) {
      case PresentationMode.page:
        await Navigator.push(context, MaterialPageRoute(builder: (ctx) => builder(ctx, moduleContext)));
      case PresentationMode.wizard:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => builder(ctx, moduleContext), fullscreenDialog: true),
        );
      case PresentationMode.modal:
        await showDialog<void>(context: context, builder: (ctx) => builder(ctx, moduleContext));
      case PresentationMode.bottomSheet:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => builder(ctx, moduleContext),
        );
      case PresentationMode.drawer:
        // Drawer é declarativo no Flutter (precisa estar em
        // Scaffold.endDrawer, não dá pra "empurrar" um builder ad-hoc como
        // nos outros modos) — quem usa esse modo precisa ligar o mesmo
        // screenBuilder ao endDrawer do próprio Scaffold. Aqui só abre.
        Scaffold.of(context).openEndDrawer();
      case PresentationMode.deepLink:
        // Sem módulo usando ainda — fora de escopo até existir um caso real.
        break;
    }
  }
}
