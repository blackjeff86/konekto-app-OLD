import crypto from 'node:crypto'

// Prefixo derivado do próprio hotelId (ex: "hotel_1" -> "HOTEL1") — não
// resolve unicidade sozinho (a coluna já é @unique), é só pra deixar
// auditável a olho nu de qual hotel é cada código, evitando qualquer
// confusão entre códigos de hotéis diferentes.
function hotelTag(hotelId: string): string {
  return hotelId.toUpperCase().replace(/[^A-Z0-9]/g, '')
}

export function generateAccessCode(hotelId: string): string {
  return `${hotelTag(hotelId)}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`
}
