/// Achata `stay.room.number` de volta pra `stay.roomNumber` nas respostas
/// da API — mantém o formato que os clientes (portal, app do hóspede) já
/// esperavam antes do quarto virar uma entidade própria (`Room`), sem
/// precisar atualizar nenhum modelo Dart por causa da mudança de onde o
/// número do quarto mora no schema.
export function flattenStayRoomNumber<T extends { room: { number: string } }>(
  stay: T,
): Omit<T, 'room'> & { roomNumber: string } {
  const { room, ...rest } = stay
  return { ...rest, roomNumber: room.number }
}
