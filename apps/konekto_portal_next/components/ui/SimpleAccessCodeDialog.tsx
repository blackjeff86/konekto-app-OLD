'use client'

import { Modal } from '@/components/ui/Modal'
import { CopyableCodeBox } from '@/components/ui/CopyableCodeBox'

/**
 * Versão enxuta do diálogo de código de acesso — só o código, sem a
 * mensagem pronta de convite (essa fica só na tela Hóspedes, ver
 * components/guests/AccessCodeDialog.tsx). Portado de
 * _showAccessCodeDialog em rooms_page.dart / stay_detail_page.dart.
 */
export function SimpleAccessCodeDialog({
  accessCode,
  onClose,
  title = 'Hóspede criado',
}: {
  accessCode: string
  onClose: () => void
  title?: string
}) {
  return (
    <Modal
      title={title}
      onClose={onClose}
      footer={
        <button type="button" onClick={onClose} className="text-sm text-slate">
          Fechar
        </button>
      }
    >
      <div className="flex flex-col gap-2">
        <p className="text-[13px] text-cream">Código de acesso:</p>
        <CopyableCodeBox value={accessCode} />
      </div>
    </Modal>
  )
}
