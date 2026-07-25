import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { ImageUploadField } from './ImageUploadField'

vi.mock('@/lib/auth/AuthProvider', () => ({ useAuth: vi.fn() }))
vi.mock('@/lib/api/uploads', () => ({ uploadImage: vi.fn() }))

import { useAuth } from '@/lib/auth/AuthProvider'
import { uploadImage } from '@/lib/api/uploads'

function mockAuthenticated() {
  vi.mocked(useAuth).mockReturnValue({
    session: { uid: 'u1', hotelId: 'h1', role: 'gerente', name: 'Ana', email: 'a@a.com' },
    token: 'tok',
    status: 'authenticated',
    errorCode: null,
    signInWithToken: vi.fn(),
    signOut: vi.fn(),
  })
}

describe('ImageUploadField', () => {
  afterEach(() => vi.clearAllMocks())

  it('calls onChange as the user types a URL directly', async () => {
    mockAuthenticated()
    const onChange = vi.fn()
    render(<ImageUploadField label="URL da imagem" value="" onChange={onChange} />)

    await userEvent.type(screen.getByLabelText('URL da imagem'), 'x')

    expect(onChange).toHaveBeenCalledWith('x')
  })

  it('uploads the selected file and calls onChange with the returned url', async () => {
    mockAuthenticated()
    vi.mocked(uploadImage).mockResolvedValue('https://blob.example/img.png')
    const onChange = vi.fn()
    const { container } = render(<ImageUploadField label="Imagem" value="" onChange={onChange} />)

    const fileInput = container.querySelector('input[type="file"]') as HTMLInputElement
    const file = new File(['data'], 'photo.png', { type: 'image/png' })
    await userEvent.upload(fileInput, file)

    await waitFor(() => expect(onChange).toHaveBeenCalledWith('https://blob.example/img.png'))
    expect(uploadImage).toHaveBeenCalledWith('h1', 'tok', file)
  })

  it('shows an error message when the upload fails', async () => {
    mockAuthenticated()
    vi.mocked(uploadImage).mockRejectedValue(new Error('Imagem muito grande — o limite é 4MB.'))
    const { container } = render(<ImageUploadField label="Imagem" value="" onChange={vi.fn()} />)

    const fileInput = container.querySelector('input[type="file"]') as HTMLInputElement
    await userEvent.upload(fileInput, new File(['data'], 'big.png', { type: 'image/png' }))

    expect(await screen.findByText('Imagem muito grande — o limite é 4MB.')).toBeInTheDocument()
  })

  it('renders a preview image for a network URL value', () => {
    mockAuthenticated()
    render(
      <ImageUploadField label="Imagem" value="https://blob.example/img.png" onChange={vi.fn()} />,
    )

    expect(screen.getByAltText('Imagem')).toBeInTheDocument()
  })

  it('shows explanatory text instead of a preview for a non-network (legacy asset) value', () => {
    mockAuthenticated()
    render(
      <ImageUploadField
        label="Imagem"
        value="assets/tenant_assets/hotels/hotel_1/images/x.png"
        onChange={vi.fn()}
      />,
    )

    expect(screen.getByText(/imagem padrão do sistema/i)).toBeInTheDocument()
  })
})
