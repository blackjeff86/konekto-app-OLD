import { randomUUID } from 'crypto'
import { put } from '@vercel/blob'

const ALLOWED_CONTENT_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/gif': 'gif',
  'image/avif': 'avif',
}

const MAX_BYTES = 4 * 1024 * 1024

// Confere os primeiros bytes do arquivo contra a assinatura real do
// formato — o `contentType` declarado vem do cliente (a extensão do
// arquivo escolhido, do lado do Flutter), então sozinho não garante que o
// conteúdo é mesmo uma imagem daquele tipo. Sem isso, alguém batendo
// direto na API (fora do app) poderia rotular qualquer arquivo como
// `image/jpeg` e ele seria aceito e servido de volta com esse
// Content-Type.
function matchesSignature(contentType: string, bytes: Uint8Array): boolean {
  const startsWith = (offset: number, signature: number[]) =>
    signature.every((byte, index) => bytes[offset + index] === byte)
  const asciiAt = (offset: number, text: string) =>
    startsWith(offset, [...text].map((char) => char.charCodeAt(0)))

  switch (contentType) {
    case 'image/jpeg':
      return startsWith(0, [0xff, 0xd8, 0xff])
    case 'image/png':
      return startsWith(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    case 'image/gif':
      return asciiAt(0, 'GIF87a') || asciiAt(0, 'GIF89a')
    case 'image/webp':
      return asciiAt(0, 'RIFF') && asciiAt(8, 'WEBP')
    case 'image/avif':
      return asciiAt(4, 'ftyp') && (asciiAt(8, 'avif') || asciiAt(8, 'avis'))
    default:
      return false
  }
}

export type UploadImageResult =
  | { ok: true; url: string }
  | { ok: false; error: 'invalid_content_type' | 'file_too_large' }

/// Sobe uma imagem enviada pelo staff pro Vercel Blob — usado pelos 5
/// campos de imagem do portal (logo, carrossel, banner de Serviços, item
/// do cardápio, cupom). Mesma allowlist de tipo do `image-proxy`
/// (`lib/ssrf-guard.ts` não se aplica aqui — esse é conteúdo enviado
/// direto pelo usuário, não uma URL de terceiro), **sem SVG**: aceitar
/// SVG enviado pelo usuário é um vetor clássico de XSS armazenado se um
/// dia for renderizado fora de `<img>`/`Image.network`.
///
/// O nome do arquivo do usuário NUNCA é usado no path — sempre um UUID
/// gerado no servidor, evitando colisão e qualquer tentativa de path
/// traversal via nome de arquivo malicioso.
export async function uploadImage(input: {
  hotelId: string
  contentType: string
  bytes: Uint8Array
}): Promise<UploadImageResult> {
  const extension = ALLOWED_CONTENT_TYPES[input.contentType]
  if (!extension) {
    return { ok: false, error: 'invalid_content_type' }
  }
  if (input.bytes.byteLength > MAX_BYTES) {
    return { ok: false, error: 'file_too_large' }
  }
  if (!matchesSignature(input.contentType, input.bytes)) {
    return { ok: false, error: 'invalid_content_type' }
  }

  const pathname = `hotels/${input.hotelId}/${randomUUID()}.${extension}`
  const blob = await put(pathname, Buffer.from(input.bytes), {
    access: 'public',
    contentType: input.contentType,
  })

  return { ok: true, url: blob.url }
}
