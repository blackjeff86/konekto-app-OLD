import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma escolhido pelo hóspede — persistido localmente (sobrevive a um
/// refresh da página) e lido uma vez no boot do app, antes do primeiro
/// frame, pra não piscar em português e depois trocar. Sem Provider/Riverpod
/// no projeto — um `ValueNotifier` global é o jeito mais simples de
/// notificar o `MaterialApp` raiz quando o hóspede troca de idioma no
/// Perfil.
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'konekto_locale';
  static const supportedLocales = [Locale('pt'), Locale('en'), Locale('es')];

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('pt'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      locale.value = Locale(saved);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }
}
