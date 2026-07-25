'use client'

import { Modal } from '@/components/ui/Modal'
import { CopyableCodeBox } from '@/components/ui/CopyableCodeBox'
import { guestAppUrl } from '@/lib/guestAppConfig'
import { guestFullName, type Guest } from '@/types/guest'

function inviteMessage(guest: Guest): string {
  return (
    `Olá, ${guestFullName(guest)}! Seu check-in foi confirmado (quarto ${guest.stay.roomNumber}).\n` +
    `Acesse ${guestAppUrl} e digite o código ${guest.accessCode} para começar.`
  )
}

/** Portado de _showAccessCodeDialog (apps/konekto_portal/lib/features/guests/guests_page.dart). */
export function AccessCodeDialog({ guest, onClose }: { guest: Guest; onClose: () => void }) {
  return (
    <Modal
      title="Hóspede criado"
      onClose={onClose}
      footer={
        <button type="button" onClick={onClose} className="text-sm text-slate">
          Fechar
        </button>
      }
    >
      <div className="flex flex-col gap-2">
        <p className="text-[13px] text-cream">Código de acesso:</p>
        <CopyableCodeBox value={guest.accessCode} />
        <p className="mt-2 text-[13px] text-cream">
          Ou copie a mensagem pronta pra mandar por WhatsApp/e-mail:
        </p>
        <button
          type="button"
          onClick={() => navigator.clipboard.writeText(inviteMessage(guest))}
          className="w-full rounded-[10px] border border-border-strong py-2.5 text-[13px] font-medium text-gold-light"
        >
          Copiar mensagem
        </button>
      </div>
    </Modal>
  )
}
