import 'package:flutter/material.dart';
import 'package:konekto/theme/theme_overlay.dart';

/// Overlays sazonais de referência (ver Theme Engine) — data-driven ou
/// ligados manualmente pelo konekto_admin no futuro; nenhum dos dois está
/// ligado a nenhum hotel ainda nesta fase, só a infraestrutura pra existir
/// sem tocar em template nenhum quando for ativado.
final christmasOverlay = ThemeOverlay(
  id: 'christmas',
  colorTransform: (base) => base.copyWith(primary: const Color(0xFFB3261E), secondary: const Color(0xFF1B5E20)),
);

final carnivalOverlay = ThemeOverlay(
  id: 'carnival',
  colorTransform: (base) => base.copyWith(primary: const Color(0xFF6A1B9A), secondary: const Color(0xFFFDD835)),
);
