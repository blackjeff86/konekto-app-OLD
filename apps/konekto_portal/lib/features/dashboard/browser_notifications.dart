import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Fininha camada sobre a Notification API do navegador — permissão e
/// exibição, sem service worker (não é Web Push de verdade: só funciona
/// enquanto o portal está aberto no navegador, mas não exige a
/// infraestrutura de push). Falha silenciosamente se o navegador não
/// suportar ou a permissão for negada — o alerta sonoro/visual dentro do
/// app continua funcionando de qualquer forma.
class BrowserNotifications {
  static Future<void> requestPermissionIfNeeded() async {
    try {
      if (web.Notification.permission == 'default') {
        await web.Notification.requestPermission().toDart;
      }
    } catch (_) {
      // Navegador sem suporte à Notification API — segue sem notificar.
    }
  }

  static void show({required String title, required String body}) {
    try {
      if (web.Notification.permission != 'granted') return;
      web.Notification(title, web.NotificationOptions(body: body, icon: 'icons/Icon-192.png'));
    } catch (_) {
      // Ignora falhas de plataforma (ex: iOS Safari sem suporte).
    }
  }
}
