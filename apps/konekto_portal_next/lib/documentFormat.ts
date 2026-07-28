import type { DocumentType } from '@/types/guest'

function onlyDigits(value: string): string {
  return value.replace(/\D/g, '')
}

function onlyAlphaNumeric(value: string): string {
  return value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase()
}

export function normalizeDocumentNumber(documentType: DocumentType, value: string): string {
  if (documentType === 'passport') return onlyAlphaNumeric(value).slice(0, 12)
  if (documentType === 'other') return onlyDigits(value).slice(0, 9)
  return onlyDigits(value).slice(0, 11)
}

export function formatDocumentNumber(documentType: DocumentType, value: string): string {
  const normalized = normalizeDocumentNumber(documentType, value)

  if (documentType === 'passport') return normalized

  if (documentType === 'other') {
    const part1 = normalized.slice(0, 2)
    const part2 = normalized.slice(2, 5)
    const part3 = normalized.slice(5, 8)
    const part4 = normalized.slice(8, 9)

    return [part1, part2, part3]
      .filter(Boolean)
      .join('.')
      .concat(part4 ? `-${part4}` : '')
  }

  const part1 = normalized.slice(0, 3)
  const part2 = normalized.slice(3, 6)
  const part3 = normalized.slice(6, 9)
  const part4 = normalized.slice(9, 11)

  return [part1, part2, part3]
    .filter(Boolean)
    .join('.')
    .concat(part4 ? `-${part4}` : '')
}

export function documentLabel(documentType: DocumentType): string {
  if (documentType === 'cpf') return 'CPF'
  if (documentType === 'other') return 'Identidade'
  return 'Passaporte'
}

export function documentInputMode(documentType: DocumentType): 'text' | 'numeric' {
  return documentType === 'passport' ? 'text' : 'numeric'
}
