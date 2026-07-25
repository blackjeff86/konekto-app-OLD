'use client'

import type { ReactNode } from 'react'

interface ModalProps {
  title: string
  onClose: () => void
  children: ReactNode
  footer: ReactNode
}

/** Modal genérico — usado pelos diálogos de formulário/confirmação de cada recurso de Configurações. */
export function Modal({ title, onClose, children, footer }: ModalProps) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      onClick={onClose}
      role="presentation"
    >
      <div
        className="max-h-[90vh] w-full max-w-[480px] overflow-y-auto rounded-2xl border border-border-strong bg-surface p-6"
        onClick={(event) => event.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label={title}
      >
        <h2 className="mb-4 text-base font-bold text-cream">{title}</h2>
        {children}
        <div className="mt-5 flex justify-end gap-3">{footer}</div>
      </div>
    </div>
  )
}
