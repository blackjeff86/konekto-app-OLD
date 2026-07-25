'use client'

import { QRCodeSVG } from 'qrcode.react'
import { guestAppUrl } from '@/lib/guestAppConfig'

/**
 * QR code fixo apontando pro app do hóspede — portado de _ReceptionQrCard
 * (apps/konekto_portal/lib/features/settings/settings_page.dart).
 */
export function ReceptionQrCard() {
  return (
    <div className="flex items-center gap-4 rounded-2xl border border-border-strong bg-surface p-5">
      <div className="rounded-[10px] bg-white p-2">
        <QRCodeSVG value={guestAppUrl} size={72} />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-bold text-cream">QR code de recepção</p>
        <p className="mt-0.5 text-xs text-slate">
          Imprima e deixe na recepção — o hóspede escaneia, abre o app e digita o código
          individual dele.
        </p>
        <p className="mt-2 truncate text-xs text-gold-light">{guestAppUrl}</p>
      </div>
      <button
        type="button"
        aria-label="Copiar link"
        onClick={() => navigator.clipboard.writeText(guestAppUrl)}
        className="shrink-0 text-slate"
      >
        ⧉
      </button>
    </div>
  )
}
