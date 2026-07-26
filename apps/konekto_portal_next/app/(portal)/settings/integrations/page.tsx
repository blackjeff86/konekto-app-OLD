'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { CopyableCodeBox } from '@/components/ui/CopyableCodeBox'
import { useIntegration } from '@/hooks/useIntegration'
import { API_BASE_URL } from '@/lib/api/client'

/**
 * Integração com o PMS/sistema de hotelaria do hotel — portado de
 * IntegrationSection (apps/konekto_portal/lib/features/settings/
 * integration_section.dart). Diferente das outras seções, aqui não
 * editamos dado nenhum: geramos uma chave de API pra esse sistema (ou um
 * middleware tipo Zapier/Make/n8n) empurrar reservas/hóspedes/cardápio pro
 * Konekto, e configuramos um webhook pra onde o Konekto manda os pedidos
 * feitos pelo hóspede no app.
 */
export default function IntegrationsPage() {
  const { status, isLoading, error, rotateApiKey, setWebhookUrl } = useIntegration()
  const [webhookUrl, setWebhookUrlInput] = useState('')
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false)
  const [isRotating, setIsRotating] = useState(false)
  const [isSavingWebhook, setIsSavingWebhook] = useState(false)
  const [confirmingRotate, setConfirmingRotate] = useState(false)
  const [revealedApiKey, setRevealedApiKey] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  if (status && !hasLoadedOnce) {
    setWebhookUrlInput(status.webhookUrl ?? '')
    setHasLoadedOnce(true)
  }

  async function handleConfirmRotate() {
    setConfirmingRotate(false)
    setIsRotating(true)
    setActionError(null)
    try {
      const apiKey = await rotateApiKey()
      setRevealedApiKey(apiKey)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao gerar a chave.')
    } finally {
      setIsRotating(false)
    }
  }

  async function handleSaveWebhook() {
    setIsSavingWebhook(true)
    setActionError(null)
    try {
      const trimmed = webhookUrl.trim()
      await setWebhookUrl(trimmed || null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao salvar a URL do webhook.')
    } finally {
      setIsSavingWebhook(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-lg font-bold text-cream">Integração com o PMS</h1>
        <p className="mt-1 text-[12.5px] text-slate">
          Conecte o sistema que o hotel já usa (ou um middleware como Zapier/Make/n8n) pra que
          reservas, hóspedes e cardápio sincronizem automaticamente pro Sevvn, e os pedidos feitos
          pelo hóspede no app voltem pro sistema do hotel.
        </p>
      </div>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <div className="rounded-2xl border border-border-strong bg-surface p-6">
        <h2 className="text-base font-bold text-cream">Chave de API</h2>
        <p className="mt-1 text-[12.5px] text-slate">
          {status?.configured
            ? `Chave atual: ${status.apiKeyPrefix}••••  ·  última sincronização recebida: ${formatLocalTimestamp(status.lastInboundSyncAt)}`
            : 'Nenhuma chave gerada ainda.'}
        </p>
        <button
          type="button"
          onClick={() => setConfirmingRotate(true)}
          disabled={isRotating}
          className="mt-4 rounded-full bg-gold px-5 py-2.5 text-sm font-bold text-ink disabled:opacity-60"
        >
          {isRotating ? 'Gerando...' : status?.configured ? 'Gerar nova chave' : 'Gerar chave'}
        </button>
      </div>

      <div className="rounded-2xl border border-border-strong bg-surface p-6">
        <h2 className="text-base font-bold text-cream">Webhook de pedidos</h2>
        <p className="mt-1 text-[12.5px] text-slate">
          URL do sistema do hotel (ou middleware) que recebe cada pedido feito pelo hóspede no app.
          Último envio: {formatLocalTimestamp(status?.lastOutboundAt ?? null)}
          {status?.lastOutboundOk === false ? ' (falhou)' : ''}
        </p>
        <label className="mt-4 block text-xs text-slate">
          URL do webhook
          <input
            type="text"
            value={webhookUrl}
            onChange={(event) => setWebhookUrlInput(event.target.value)}
            placeholder="https://..."
            className="mt-1 block w-full rounded-[10px] border border-border-strong bg-black/3 px-3.5 py-3 text-sm text-cream outline-none focus:border-gold"
          />
        </label>
        <button
          type="button"
          onClick={handleSaveWebhook}
          disabled={isSavingWebhook}
          className="mt-4 rounded-full bg-gold px-5 py-2.5 text-sm font-bold text-ink disabled:opacity-60"
        >
          {isSavingWebhook ? 'Salvando...' : 'Salvar'}
        </button>
      </div>

      <HowToConnectPanel />

      {confirmingRotate && (
        <Modal
          title={status?.configured ? 'Gerar nova chave?' : 'Gerar chave de integração?'}
          onClose={() => setConfirmingRotate(false)}
          footer={
            <>
              <button type="button" onClick={() => setConfirmingRotate(false)} className="text-sm text-slate">
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmRotate} className="text-sm font-semibold text-gold-light">
                Gerar
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            {status?.configured
              ? 'A chave atual deixa de funcionar imediatamente — quem já usa precisa trocar pela nova.'
              : 'Essa chave é o que o PMS (ou o middleware que o hotel usar) precisa pra enviar dados pro Sevvn.'}
          </p>
        </Modal>
      )}

      {revealedApiKey && (
        <Modal
          title="Chave gerada"
          onClose={() => setRevealedApiKey(null)}
          footer={
            <button type="button" onClick={() => setRevealedApiKey(null)} className="text-sm text-slate">
              Fechar
            </button>
          }
        >
          <p className="mb-3 text-[12.5px] text-gold">
            Essa chave não vai ser mostrada de novo — copie e guarde num lugar seguro antes de
            fechar.
          </p>
          <CopyableCodeBox value={revealedApiKey} fontSize={13} />
        </Modal>
      )}
    </div>
  )
}

function formatLocalTimestamp(iso: string | null): string {
  if (!iso) return 'Nunca'
  const date = new Date(iso)
  const day = date.getDate().toString().padStart(2, '0')
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const hour = date.getHours().toString().padStart(2, '0')
  const minute = date.getMinutes().toString().padStart(2, '0')
  return `${day}/${month}/${date.getFullYear()} ${hour}:${minute}`
}

function HowToConnectPanel() {
  return (
    <details className="rounded-2xl border border-border-strong bg-surface p-6">
      <summary className="cursor-pointer text-base font-bold text-cream">Como conectar</summary>
      <div className="mt-4 flex flex-col gap-3">
        <p className="text-[12.5px] text-slate">
          Use a chave gerada acima como Bearer token nesses endpoints. Reenviar o mesmo id sempre
          atualiza (nunca duplica).
        </p>
        <EndpointDoc
          method="PUT"
          path="/api/integrations/v1/reservations/{id}"
          description="Cria/atualiza uma reserva de quarto (com os hóspedes vinculados)."
        />
        <EndpointDoc
          method="PUT"
          path="/api/integrations/v1/menu-categories/{id}"
          description="Cria/atualiza uma categoria do cardápio/serviços."
        />
        <EndpointDoc
          method="PUT"
          path="/api/integrations/v1/menu-items/{id}"
          description="Cria/atualiza um item dentro de uma categoria já sincronizada."
        />
        <p className="mt-2 text-xs text-slate">Exemplo</p>
        <pre className="overflow-x-auto rounded-[10px] bg-black/25 p-3.5 text-[11.5px] text-cream">
          {`curl -X PUT ${API_BASE_URL}/api/integrations/v1/menu-categories/cat-001 \\
  -H "Authorization: Bearer SUA_CHAVE" \\
  -H "Content-Type: application/json" \\
  -d '{"name":"Room Service","icon":"room_service","description":"","type":"room_service","category":"Room Service"}'`}
        </pre>
      </div>
    </details>
  )
}

function EndpointDoc({ method, path, description }: { method: string; path: string; description: string }) {
  return (
    <div>
      <div className="flex items-start gap-2">
        <span className="shrink-0 rounded-md bg-gold/15 px-2 py-0.5 text-[11px] font-bold text-gold">
          {method}
        </span>
        <span className="text-[12.5px] text-cream">{path}</span>
      </div>
      <p className="mt-1 text-xs text-slate">{description}</p>
    </div>
  )
}
