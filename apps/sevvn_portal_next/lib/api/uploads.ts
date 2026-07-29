/**
 * Portado de apps/konekto_portal/lib/data/upload_repository.dart. Usa
 * multipart/form-data (não JSON), então não reaproveita apiRequest —
 * espelha o mesmo request cru (campo "file") e o mesmo mapeamento de
 * status code (415/413/genérico).
 */
import { API_BASE_URL, ApiError } from './client'

export async function uploadImage(hotelId: string, token: string, file: File): Promise<string> {
  const formData = new FormData()
  formData.append('file', file, file.name)

  let response: Response
  try {
    response = await fetch(`${API_BASE_URL}/api/hotels/${hotelId}/uploads`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: formData,
    })
  } catch {
    throw new ApiError('Não foi possível conectar ao servidor. Tente novamente.', 0)
  }

  if (response.status === 415) {
    throw new ApiError(
      'Formato de imagem não suportado — use JPEG, PNG, WebP, GIF ou AVIF.',
      415,
    )
  }
  if (response.status === 413) {
    throw new ApiError('Imagem muito grande — o limite é 4MB.', 413)
  }
  if (!response.ok) {
    throw new ApiError(`Falha ao enviar a imagem (status ${response.status}).`, response.status)
  }

  const body = (await response.json()) as { url: string }
  return body.url
}
