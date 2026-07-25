import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';
import 'package:konekto/theme/seasonal_overlays.dart';
import 'package:konekto/theme/theme_engine.dart';
import 'package:konekto/theme/theme_overlay.dart';

final _base = GuestTemplateTheme(
  colors: const ColorScheme.light(primary: Color(0xFF4F378A), secondary: Color(0xFFC9A227)),
  displayFontFamily: GoogleFonts.playfairDisplay().fontFamily!,
  bodyFontFamily: GoogleFonts.workSans().fontFamily!,
  radiusSm: 4,
  radiusDefault: 8,
  radiusMd: 12,
  radiusLg: 16,
  radiusXl: 24,
);

void main() {
  group('ThemeEngine.resolve', () {
    test('returns the base theme unchanged when no overlay/dark mode/brand override is given', () {
      final result = ThemeEngine.resolve(base: _base);
      expect(result, same(_base));
    });

    test('preserves typography and radius scale from the base template regardless of overlays', () {
      final result = ThemeEngine.resolve(base: _base, darkMode: true);
      expect(result.displayFontFamily, _base.displayFontFamily);
      expect(result.bodyFontFamily, _base.bodyFontFamily);
      expect(result.radiusLg, _base.radiusLg);
    });

    test('darkMode swaps the color scheme brightness without touching the base instance', () {
      final result = ThemeEngine.resolve(base: _base, darkMode: true);
      expect(result.colors.brightness, Brightness.dark);
      expect(_base.colors.brightness, Brightness.light);
    });

    test('applies a seasonal overlay color transform on top of the base palette', () {
      final result = ThemeEngine.resolve(base: _base, seasonal: christmasOverlay);
      expect(result.colors.primary, const Color(0xFFB3261E));
      expect(result.colors.secondary, const Color(0xFF1B5E20));
    });

    test('a hotel brand override sets the accent (primary) color', () {
      final result = ThemeEngine.resolve(base: _base, brandOverride: const HotelBrandOverride(accentColor: Color(0xFF00FF00)));
      expect(result.colors.primary, const Color(0xFF00FF00));
    });

    test('brand override is applied on top of a seasonal overlay when both are present', () {
      final result = ThemeEngine.resolve(
        base: _base,
        seasonal: carnivalOverlay,
        brandOverride: const HotelBrandOverride(accentColor: Color(0xFF00FF00)),
      );
      expect(result.colors.primary, const Color(0xFF00FF00));
      // secondary não foi sobrescrito pelo brand override — continua vindo do overlay sazonal.
      expect(result.colors.secondary, const Color(0xFFFDD835));
    });

    test('a brand override without accentColor set does not change the palette', () {
      final result = ThemeEngine.resolve(base: _base, brandOverride: const HotelBrandOverride());
      expect(result.colors.primary, _base.colors.primary);
    });
  });
}
