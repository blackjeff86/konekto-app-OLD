'use client'

import { useQuery } from '@tanstack/react-query'
import { useEffect, useRef } from 'react'
import { useAuth } from '@/lib/auth/AuthProvider'
import { listOrders } from '@/lib/api/orders'
import { getUnreadMessagesCount } from '@/lib/api/stays'
import { listSupportMessages } from '@/lib/api/support'
import { browserNotifications } from '@/lib/browserNotifications'
import { playNewOrderSound } from '@/lib/newOrderSound'
import { isSupportMessageFromPlatform } from '@/types/support'
import type { Order } from '@/types/order'

const POLL_INTERVAL_MS = 5000

function notifyNewOrders(newOrders: Order[]): void {
  playNewOrderSound()
  const first = newOrders[0]
  const title = newOrders.length === 1 ? 'Novo pedido' : `${newOrders.length} novos pedidos`
  const body =
    newOrders.length === 1
      ? `${first.itemName} · ${first.guestName} · Quarto ${first.guestRoomNumber}`
      : `O mais recente: ${first.itemName} · Quarto ${first.guestRoomNumber}`
  browserNotifications.show({ title, body })
}

export interface PortalBadgeCounts {
  pendingOrderCount: number
  unreadMessagesCount: number
  unreadSupportCount: number
}

/**
 * Portado da lógica de polling/notificação de DashboardPage (apps/
 * konekto_portal/lib/features/dashboard/dashboard_page.dart) — roda
 * continuamente (não só na aba Pedidos/Quartos/Suporte), montado no
 * layout autenticado sempre-ativo, pra alertar sobre pedido/mensagem novos
 * em qualquer seção do portal. Também devolve as contagens usadas nos
 * badges do PortalSidebar (Pedidos/Quartos/Suporte).
 *
 * Usa a MESMA queryKey que useOrders/useSupport (['orders', hotelId] /
 * ['support-messages', hotelId]) — o polling daqui alimenta o cache que
 * essas páginas também leem, sem duplicar requisições quando ambas estão
 * montadas.
 */
export function useOrderNotifications(): PortalBadgeCounts {
  const { session, token } = useAuth()
  const hotelId = session?.hotelId
  const enabled = Boolean(hotelId && token)

  useEffect(() => {
    browserNotifications.requestPermissionIfNeeded()
  }, [])

  const ordersQuery = useQuery({
    queryKey: ['orders', hotelId],
    queryFn: () => listOrders(hotelId!, token!),
    enabled,
    refetchInterval: POLL_INTERVAL_MS,
  })
  const knownOrderIds = useRef<Set<string> | null>(null)

  useEffect(() => {
    if (!ordersQuery.data) return
    if (knownOrderIds.current) {
      const newOrders = ordersQuery.data.filter((order) => !knownOrderIds.current!.has(order.id))
      if (newOrders.length > 0) notifyNewOrders(newOrders)
    }
    knownOrderIds.current = new Set(ordersQuery.data.map((order) => order.id))
  }, [ordersQuery.data])

  const unreadMessagesQuery = useQuery({
    queryKey: ['unread-messages-count', hotelId],
    queryFn: () => getUnreadMessagesCount(hotelId!, token!),
    enabled,
    refetchInterval: POLL_INTERVAL_MS,
  })
  const knownUnreadMessages = useRef<number | null>(null)

  useEffect(() => {
    if (unreadMessagesQuery.data == null) return
    if (knownUnreadMessages.current != null && unreadMessagesQuery.data > knownUnreadMessages.current) {
      playNewOrderSound()
      browserNotifications.show({ title: 'Nova mensagem de hóspede', body: 'Confira em Quartos.' })
    }
    knownUnreadMessages.current = unreadMessagesQuery.data
  }, [unreadMessagesQuery.data])

  // Mantém o cache de mensagens de suporte sempre atualizado (mesmo com
  // outra seção do portal aberta), igual ao polling contínuo do app
  // Flutter — e alimenta o badge de "Suporte" no PortalSidebar.
  const supportMessagesQuery = useQuery({
    queryKey: ['support-messages', hotelId],
    queryFn: () => listSupportMessages(hotelId!, token!),
    enabled,
    refetchInterval: POLL_INTERVAL_MS,
  })

  const pendingOrderCount = (ordersQuery.data ?? []).filter((order) => order.status === 'pending').length
  const unreadSupportCount = (supportMessagesQuery.data ?? []).filter(
    (message) => isSupportMessageFromPlatform(message) && !message.readByHotel,
  ).length

  return {
    pendingOrderCount,
    unreadMessagesCount: unreadMessagesQuery.data ?? 0,
    unreadSupportCount,
  }
}
