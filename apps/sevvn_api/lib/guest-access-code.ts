import crypto from 'node:crypto'

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

function randomCode(length: number): string {
  const bytes = crypto.randomBytes(length)
  let result = ''
  for (let index = 0; index < length; index += 1) {
    result += ALPHABET[bytes[index] % ALPHABET.length]
  }
  return result
}

export function generateAccessCode(_hotelId: string): string {
  return `SV-${randomCode(6)}`
}
