'use client'

import { useState } from 'react'
import { Modal } from '@/components/ui/Modal'
import { CopyableCodeBox } from '@/components/ui/CopyableCodeBox'
import { useAuth } from '@/lib/auth/AuthProvider'
import { useStaff } from '@/hooks/useStaff'
import { staffRoleLabel } from '@/types/staffSession'
import type { StaffMember } from '@/types/staff'

function inviteLink(code: string): string {
  if (typeof window === 'undefined') return ''
  const url = new URL(window.location.href)
  url.search = ''
  url.searchParams.set('invite', code)
  return url.toString()
}

/**
 * Tela "Equipe" — portado de InviteStaffPage (apps/konekto_portal/lib/
 * features/staff/invite_staff_page.dart). Só `gerente` acessa (gate no
 * layout de Configurações). Gera um código de convite e mostra o link
 * pronto pra compartilhar (`?invite=<code>`).
 */
export default function StaffPage() {
  const { session } = useAuth()
  const { members, isLoading, error, revokeStaff, createInvite } = useStaff()
  const [revokingMember, setRevokingMember] = useState<StaffMember | null>(null)
  const [isGenerating, setIsGenerating] = useState(false)
  const [generatedCode, setGeneratedCode] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  async function handleGenerateInvite() {
    setIsGenerating(true)
    setActionError(null)
    try {
      const code = await createInvite()
      setGeneratedCode(code)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao gerar convite.')
    } finally {
      setIsGenerating(false)
    }
  }

  async function handleConfirmRevoke() {
    if (!revokingMember) return
    setActionError(null)
    try {
      await revokeStaff(revokingMember.id)
      setRevokingMember(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao revogar acesso.')
      setRevokingMember(null)
    }
  }

  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)

  return (
    <div className="flex flex-col gap-8">
      <div className="rounded-2xl border border-border-strong bg-surface p-6">
        <h1 className="text-lg font-bold text-cream">Equipe</h1>
        <p className="mt-1 text-[12.5px] text-slate">Quem já tem acesso ao portal deste hotel.</p>

        {errorMessage && (
          <div className="mt-4 rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
            {errorMessage}
          </div>
        )}

        {isLoading ? (
          <div className="mt-6 flex justify-center">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
          </div>
        ) : members.length === 0 ? (
          <p className="mt-4 text-[13.5px] text-cream">Ninguém cadastrado ainda.</p>
        ) : (
          <div className="mt-4 flex flex-col gap-3">
            {members.map((member) => (
              <div key={member.id} className="flex items-center gap-3">
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-cream">{member.name}</p>
                  <p className="truncate text-xs text-slate">
                    {member.email} · {staffRoleLabel[member.role as keyof typeof staffRoleLabel] ?? member.role}
                  </p>
                </div>
                {member.id === session?.uid ? (
                  <span className="shrink-0 text-xs text-slate">Você</span>
                ) : (
                  <button
                    type="button"
                    onClick={() => setRevokingMember(member)}
                    className="shrink-0 text-[12.5px] text-[#B3261E]"
                  >
                    Revogar
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="rounded-2xl border border-border-strong bg-surface p-6">
        <h2 className="text-base font-bold text-cream">Convidar recepção</h2>
        <p className="mt-1 text-[12.5px] text-slate">
          Gere um link de cadastro — quem acessar vira automaticamente &ldquo;Recepção&rdquo; deste
          hotel.
        </p>

        {generatedCode == null ? (
          <button
            type="button"
            onClick={handleGenerateInvite}
            disabled={isGenerating}
            className="mt-4 rounded-full bg-gold px-5 py-2.5 text-sm font-bold text-ink disabled:opacity-60"
          >
            {isGenerating ? 'Gerando...' : 'Gerar convite'}
          </button>
        ) : (
          <div className="mt-4 flex flex-col gap-4">
            <div>
              <p className="mb-1.5 text-xs text-slate">Link de cadastro</p>
              <CopyableCodeBox value={inviteLink(generatedCode)} fontSize={13} />
            </div>
            <div>
              <p className="mb-1.5 text-xs text-slate">Código</p>
              <CopyableCodeBox value={generatedCode} fontSize={16} />
            </div>
            <button
              type="button"
              onClick={() => setGeneratedCode(null)}
              className="w-fit text-[12.5px] font-semibold text-gold-light"
            >
              Gerar outro convite
            </button>
          </div>
        )}
      </div>

      {revokingMember && (
        <Modal
          title="Revogar acesso?"
          onClose={() => setRevokingMember(null)}
          footer={
            <>
              <button type="button" onClick={() => setRevokingMember(null)} className="text-sm text-slate">
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmRevoke} className="text-sm text-[#B3261E]">
                Revogar
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            &ldquo;{revokingMember.name}&rdquo; não vai mais conseguir entrar no portal deste hotel.
          </p>
        </Modal>
      )}
    </div>
  )
}
