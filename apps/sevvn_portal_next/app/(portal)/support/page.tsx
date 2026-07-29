'use client'

import { useEffect, useRef, useState } from 'react'
import { useSupport } from '@/hooks/useSupport'
import { isSupportMessageFromPlatform, type SupportMessage } from '@/types/support'

/** Portado de apps/konekto_portal/lib/features/support/support_page.dart. */
export default function SupportPage() {
  const { messages, isLoading, error, sendMessage } = useSupport()
  const [messageText, setMessageText] = useState('')
  const [isSending, setIsSending] = useState(false)
  const [sendError, setSendError] = useState<string | null>(null)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ block: 'end' })
  }, [messages.length])

  async function handleSend() {
    const trimmed = messageText.trim()
    if (!trimmed) return
    setIsSending(true)
    setSendError(null)
    try {
      await sendMessage(trimmed)
      setMessageText('')
    } catch (err) {
      setSendError(err instanceof Error ? err.message : 'Falha ao enviar a mensagem.')
    } finally {
      setIsSending(false)
    }
  }

  const errorMessage = sendError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex h-[70vh] flex-col gap-6">
      <p className="text-[13.5px] text-slate">
        Fale direto com a equipe da Sevvn — dúvidas, problemas ou pedidos de ajuda.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <div className="whisper-shadow flex flex-1 flex-col rounded-xl border border-border bg-surface p-6">
        <div className="flex-1 overflow-y-auto">
          {isLoading ? (
            <div className="flex h-full items-center justify-center">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
            </div>
          ) : messages.length === 0 ? (
            <div className="flex h-full items-center justify-center">
              <p className="text-[13.5px] text-slate">Nenhuma mensagem ainda — envie a primeira abaixo.</p>
            </div>
          ) : (
            <div className="flex flex-col gap-2.5">
              {messages.map((message) => (
                <MessageBubble key={message.id} message={message} />
              ))}
              <div ref={bottomRef} />
            </div>
          )}
        </div>

        <div className="mt-4 flex items-center gap-3 border-t border-border pt-4">
          <textarea
            value={messageText}
            onChange={(event) => setMessageText(event.target.value)}
            placeholder="Escreva sua mensagem..."
            rows={1}
            className="flex-1 rounded-xl border border-border-strong bg-surface-alt/60 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
          />
          <button
            type="button"
            onClick={handleSend}
            disabled={isSending}
            aria-label="Enviar mensagem"
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-ink text-white transition-opacity hover:opacity-90 disabled:opacity-60"
          >
            ➤
          </button>
        </div>
      </div>
    </div>
  )
}

function MessageBubble({ message }: { message: SupportMessage }) {
  const isFromPlatform = isSupportMessageFromPlatform(message)
  return (
    <div className={`flex ${isFromPlatform ? 'justify-start' : 'justify-end'}`}>
      <div
        className={`max-w-[480px] rounded-xl px-4 py-3 ${
          isFromPlatform ? 'bg-surface-alt' : 'bg-gold/12'
        }`}
      >
        <p className="text-[10px] font-bold tracking-wide text-gold-light uppercase">
          {isFromPlatform ? 'Sevvn' : 'Você'}
        </p>
        <p className="mt-1 text-[13.5px] text-cream">{message.body}</p>
      </div>
    </div>
  )
}
