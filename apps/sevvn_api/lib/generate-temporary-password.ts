import { randomInt } from 'crypto'

// Sem caracteres ambíguos (0/O, 1/l/I) — a senha é lida/digitada por uma
// pessoa (o gerente recém-criado), não colada de um gerenciador de senhas.
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789'
const LENGTH = 12

// Gera a senha temporária do primeiro acesso de um gerente recém-criado —
// só existe em texto puro na resposta desse único request (nunca é
// persistida nem fica recuperável depois, só o hash via bcrypt).
export function generateTemporaryPassword(): string {
  let password = ''
  for (let i = 0; i < LENGTH; i++) {
    password += ALPHABET[randomInt(ALPHABET.length)]
  }
  return password
}
