/**
 * Portado de apps/konekto_portal/lib/features/dashboard/browser_notifications.dart
 * — fina camada sobre a Notification API do navegador, sem service worker
 * (não é Web Push de verdade: só funciona com o portal aberto). Falha
 * silenciosamente se o navegador não suportar ou a permissão for negada.
 */
export const browserNotifications = {
  async requestPermissionIfNeeded(): Promise<void> {
    try {
      if (typeof Notification === 'undefined') return
      if (Notification.permission === 'default') {
        await Notification.requestPermission()
      }
    } catch {
      // Navegador sem suporte à Notification API — segue sem notificar.
    }
  },

  show({ title, body }: { title: string; body: string }): void {
    try {
      if (typeof Notification === 'undefined') return
      if (Notification.permission !== 'granted') return
      new Notification(title, { body, icon: '/icons/Icon-192.png' })
    } catch {
      // Ignora falhas de plataforma (ex: iOS Safari sem suporte).
    }
  },
}
