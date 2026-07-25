import 'package:flutter/material.dart';

/// Ajuste parcial por cima de um [ColorScheme] de template — nunca
/// substitui o template, só transforma (ex: evento sazonal, marca do
/// hotel). `colorTransform` recebe o `ColorScheme` já resolvido até aqui
/// (permite empilhar overlays).
class ThemeOverlay {
  final String id;
  final ColorScheme Function(ColorScheme base) colorTransform;

  const ThemeOverlay({required this.id, required this.colorTransform});
}

/// Marca do hotel — injeta a cor de destaque do hotel por cima do
/// template, sem duplicar o `colorPalette` que já vem de
/// `tenantConfig['colorPalette']` (usado hoje só nas telas
/// compartilhadas via `GuestAppTheme`) — este é o equivalente pro lado
/// dos 5 templates White Label.
class HotelBrandOverride {
  final Color? accentColor;

  const HotelBrandOverride({this.accentColor});
}
