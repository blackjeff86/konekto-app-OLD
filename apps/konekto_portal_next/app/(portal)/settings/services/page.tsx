'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Modal } from '@/components/ui/Modal'
import { ServiceFormDialog } from '@/components/settings/ServiceFormDialog'
import { ServicesPageBannerCard } from '@/components/settings/ServicesPageBannerCard'
import { useServices } from '@/hooks/useServices'
import { useHotelConfig } from '@/hooks/useHotelConfig'
import { useModulesCatalog } from '@/hooks/useModulesCatalog'
import { serviceIconFor } from '@/lib/serviceIcons'
import type { Service } from '@/types/service'

/** Portado de ServicesListPage (apps/konekto_portal/lib/features/services/services_list_page.dart). */
export default function ServicesPage() {
  const { services, isLoading, error, createService, updateService, deleteService } = useServices()
  const { config } = useHotelConfig()
  const { modules } = useModulesCatalog()
  const [editingService, setEditingService] = useState<Service | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [deletingService, setDeletingService] = useState<Service | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  // Módulos de Hospitalidade que o plano do hotel de fato permite (mesmo
  // conjunto que o backend valida na criação — presente em enabledModules
  // independente de estar ligado/desligado agora, já que criar um serviço
  // não exige o módulo estar ativo, só permitido).
  const allowedModuleIds = new Set((config?.enabledModules ?? []).map((module) => module.id))
  const allowedHospitalidadeModules = modules.filter(
    (module) => module.category === 'hospitalidade' && module.implemented && allowedModuleIds.has(module.id),
  )

  const isDialogOpen = isCreating || editingService !== null

  async function handleToggleEnabled(service: Service) {
    setActionError(null)
    try {
      await updateService({ serviceId: service.id, input: { enabled: !service.enabled } })
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao atualizar serviço.')
    }
  }

  async function handleConfirmDelete() {
    if (!deletingService) return
    setActionError(null)
    try {
      await deleteService(deletingService.id)
      setDeletingService(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao remover serviço.')
      setDeletingService(null)
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
  const categories = [...new Set(services.map((service) => service.category))]
  const existingCategories = categories

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-bold text-cream">Serviços do hotel</h1>
        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="text-[12.5px] font-semibold text-gold-light"
        >
          + Criar serviço
        </button>
      </div>
      <p className="-mt-3 text-[12.5px] text-slate">
        Cada card é um serviço que aparece no app do hóspede — crie quantos o hotel oferecer.
      </p>

      <ServicesPageBannerCard />

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {services.length === 0 ? (
        <div className="rounded-2xl border border-border-strong bg-surface p-7 text-[13.5px] text-cream">
          Nenhum serviço criado ainda.
        </div>
      ) : (
        categories.map((category) => (
          <div key={category} className="flex flex-col gap-3.5">
            <p className="text-[13px] font-bold text-slate">{category}</p>
            {services
              .filter((service) => service.category === category)
              .map((service) => (
                <ServiceRow
                  key={service.id}
                  service={service}
                  onEdit={() => setEditingService(service)}
                  onToggleEnabled={() => handleToggleEnabled(service)}
                  onDelete={() => setDeletingService(service)}
                />
              ))}
          </div>
        ))
      )}

      {isDialogOpen && (
        <ServiceFormDialog
          existing={editingService}
          existingCategories={existingCategories}
          allowedHospitalidadeModules={allowedHospitalidadeModules}
          onClose={() => {
            setIsCreating(false)
            setEditingService(null)
          }}
          onSubmitCreate={async (input) => {
            await createService(input)
            setIsCreating(false)
          }}
          onSubmitUpdate={async (input) => {
            if (!editingService) return
            await updateService({ serviceId: editingService.id, input })
            setEditingService(null)
          }}
        />
      )}

      {deletingService && (
        <Modal
          title="Remover serviço?"
          onClose={() => setDeletingService(null)}
          footer={
            <>
              <button type="button" onClick={() => setDeletingService(null)} className="text-sm text-slate">
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmDelete} className="text-sm text-[#B3261E]">
                Remover
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            &ldquo;{deletingService.name}&rdquo; e todos os seus itens serão removidos permanentemente.
          </p>
        </Modal>
      )}
    </div>
  )
}

function ServiceRow({
  service,
  onEdit,
  onToggleEnabled,
  onDelete,
}: {
  service: Service
  onEdit: () => void
  onToggleEnabled: () => void
  onDelete: () => void
}) {
  const itemCountLabel = `${service.items.length} ${service.items.length === 1 ? 'item' : 'itens'}`

  return (
    <div className="flex items-center gap-4 rounded-2xl border border-border-strong bg-surface p-[18px]">
      <div
        className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-lg"
        style={{ backgroundColor: 'rgba(255,46,136,0.1)' }}
      >
        {serviceIconFor(service.icon)}
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[14.5px] font-bold text-cream">{service.name}</p>
        <p className="truncate text-xs text-slate">
          {service.description} · {itemCountLabel}
        </p>
      </div>
      <Link href={`/settings/services/${service.id}`} className="shrink-0 text-[12.5px] text-gold-light">
        Gerenciar itens
      </Link>
      <button
        type="button"
        role="switch"
        aria-checked={service.enabled}
        aria-label={service.enabled ? 'Desativar serviço' : 'Ativar serviço'}
        onClick={onToggleEnabled}
        className="relative h-5 w-9 shrink-0 rounded-full transition-colors"
        style={{ backgroundColor: service.enabled ? 'var(--color-gold)' : 'var(--color-border-strong)' }}
      >
        <span
          className="absolute top-0.5 h-4 w-4 rounded-full bg-white transition-transform"
          style={{ transform: service.enabled ? 'translateX(18px)' : 'translateX(2px)' }}
        />
      </button>
      <button type="button" aria-label="Editar" onClick={onEdit} className="shrink-0 text-slate">
        ✎
      </button>
      <button type="button" aria-label="Remover" onClick={onDelete} className="shrink-0 text-slate">
        🗑
      </button>
    </div>
  )
}
