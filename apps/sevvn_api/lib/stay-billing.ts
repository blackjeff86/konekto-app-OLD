import type { Prisma, PrismaClient } from '@/app/generated/prisma/client'
import { prisma } from '@/lib/prisma'

/// Aceita tanto o client global quanto um `tx` de `prisma.$transaction` —
/// permite reusar o mesmo cálculo de saldo dentro da transação que
/// serializa o pagamento (ver `guest/stay-bill/pay/route.ts`), sem
/// duplicar a query.
type PrismaClientOrTx = PrismaClient | Prisma.TransactionClient

export interface StayBillOrder {
  id: string
  itemName: string
  quantity: number
  price: number
  createdAt: Date
}

export interface StayBill {
  orders: StayBillOrder[]
  totalOrders: number
  totalPaid: number
  balanceDue: number
}

/// Saldo devedor da conta consolidada de uma estadia — nunca armazenado,
/// sempre recalculado: soma de `Order.price * quantity` (pedidos não
/// cancelados, com preço definido) menos a soma dos `StayPayment.amount`
/// já pagos com sucesso. Fonte única de verdade do valor a cobrar — nunca
/// confiar num total calculado no cliente pra cobrar o cartão.
export async function computeStayBill(stayId: string, client: PrismaClientOrTx = prisma): Promise<StayBill> {
  const orders = await client.order.findMany({
    // `paymentMode: 'partner'` = hóspede paga o parceiro diretamente, sem
    // cobrança pelo Konekto — o pedido existe (aparece em Pedidos/Meus
    // Pedidos) mas não soma na conta do quarto.
    where: { guest: { stayId }, status: { not: 'cancelled' }, price: { not: null }, paymentMode: 'hotel' },
    orderBy: { createdAt: 'desc' },
    select: { id: true, itemName: true, quantity: true, price: true, createdAt: true },
  })

  const totalOrders = orders.reduce((sum, order) => sum + (order.price ?? 0) * order.quantity, 0)

  const paidAggregate = await client.stayPayment.aggregate({
    where: { stayId, status: 'paid' },
    _sum: { amount: true },
  })
  const totalPaid = paidAggregate._sum.amount ?? 0

  return {
    orders: orders.map((order) => ({
      id: order.id,
      itemName: order.itemName,
      quantity: order.quantity,
      price: order.price ?? 0,
      createdAt: order.createdAt,
    })),
    totalOrders: Math.round(totalOrders * 100) / 100,
    totalPaid: Math.round(totalPaid * 100) / 100,
    balanceDue: Math.max(0, Math.round((totalOrders - totalPaid) * 100) / 100),
  }
}
