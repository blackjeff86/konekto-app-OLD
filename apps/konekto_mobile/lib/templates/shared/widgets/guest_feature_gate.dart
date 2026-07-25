import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_features.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Porteiro de feature premium: só renderiza [builder] quando [flag] está
/// ligada em [features] — senão mostra um estado de bloqueio simples. É a
/// peça que faz a Task 10 (telas premium-only) de fato depender do
/// `GuestFeatures` construído na Task 6, em vez de cada tela decidir
/// sozinha se deve aparecer.
class GuestFeatureGate extends StatelessWidget {
  final GuestFeatures features;
  final GuestFeatureFlag flag;
  final GuestTemplateTheme theme;
  final String lockedTitle;
  final String lockedMessage;
  final WidgetBuilder builder;

  const GuestFeatureGate({
    super.key,
    required this.features,
    required this.flag,
    required this.theme,
    required this.lockedTitle,
    required this.lockedMessage,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (features.has(flag)) return builder(context);

    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
                  child: Icon(Icons.lock_outline, color: colors.outline, size: 28),
                ),
                const SizedBox(height: 20),
                Text(lockedTitle, textAlign: TextAlign.center, style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface)),
                const SizedBox(height: 8),
                Text(lockedMessage, textAlign: TextAlign.center, style: theme.body(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
