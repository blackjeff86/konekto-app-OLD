import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';
import 'package:konekto/theme/theme_overlay.dart';

/// Theme Engine — recebe o [GuestTemplateTheme] BASE de cada template
/// (`auraTheme`, `eliteTheme`, ... já existentes, sem mudança) e compõe
/// overlays por cima (dark mode, sazonal, marca do hotel) antes de
/// entregar pro Presentation Engine renderizar. Não substitui
/// `GuestAppTheme`/`GuestTemplateTheme` já existentes — fica ACIMA deles,
/// compondo, nunca duplicando os tokens fixos.
class ThemeEngine {
  const ThemeEngine._();

  static GuestTemplateTheme resolve({
    required GuestTemplateTheme base,
    ThemeOverlay? seasonal,
    bool darkMode = false,
    HotelBrandOverride? brandOverride,
  }) {
    var colors = base.colors;
    if (darkMode) colors = _toDark(colors);
    if (seasonal != null) colors = seasonal.colorTransform(colors);
    if (brandOverride?.accentColor != null) colors = colors.copyWith(primary: brandOverride!.accentColor);

    if (identical(colors, base.colors)) return base;

    return GuestTemplateTheme(
      colors: colors,
      displayFontFamily: base.displayFontFamily,
      bodyFontFamily: base.bodyFontFamily,
      radiusSm: base.radiusSm,
      radiusDefault: base.radiusDefault,
      radiusMd: base.radiusMd,
      radiusLg: base.radiusLg,
      radiusXl: base.radiusXl,
    );
  }

  static ColorScheme _toDark(ColorScheme light) => ColorScheme.fromSeed(seedColor: light.primary, brightness: Brightness.dark);
}
