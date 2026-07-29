import { prisma } from '@/lib/prisma'

/// Fecha uma estadia e revoga todos os hóspedes dela — mesma operação do
/// "Fechar conta" manual (`PATCH .../stays/:stayId` com `close: true`), só
/// que disparada automaticamente quando alguém percebe que o check-out já
/// passou (login/requisição do hóspede, ou uma listagem do portal), não por
/// ação do staff.
export async function expireStay(stayId: string): Promise<void> {
  await prisma.$transaction([
    prisma.stay.update({ where: { id: stayId }, data: { status: 'closed' } }),
    prisma.guest.updateMany({ where: { stayId }, data: { status: 'revoked' } }),
  ])
}

/// Varre e fecha todas as estadias `active` de um hotel cujo check-out já
/// passou. Sem infra de cron neste projeto ainda, então a expiração é
/// "preguiçosa": chamada no início das listagens do portal (Quartos,
/// Hóspedes) pra status mostrado sempre bater com a realidade, mesmo se
/// ninguém clicou em "Fechar conta". O bloqueio de acesso do hóspede em si
/// (o que realmente importa pra segurança) não depende disso — é reforçado
/// direto em `requireGuestAuth`/`guest/claim`, que revalidam contra o banco
/// a cada requisição.
export async function sweepExpiredStays(hotelId: string): Promise<void> {
  const overdue = await prisma.stay.findMany({
    where: { hotelId, status: 'active', checkOutDate: { lt: new Date() } },
    select: { id: true },
  })
  if (overdue.length === 0) return

  const stayIds = overdue.map((stay) => stay.id)
  await prisma.$transaction([
    prisma.stay.updateMany({ where: { id: { in: stayIds } }, data: { status: 'closed' } }),
    prisma.guest.updateMany({ where: { stayId: { in: stayIds } }, data: { status: 'revoked' } }),
  ])
}
