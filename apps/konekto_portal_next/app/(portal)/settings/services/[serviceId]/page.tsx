'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { Modal } from '@/components/ui/Modal'
import { ServiceItemFormDialog } from '@/components/settings/ServiceItemFormDialog'
import { RestaurantOperationsPanel } from '@/components/settings/RestaurantOperationsPanel'
import { TableTypeFormDialog } from '@/components/settings/TableTypeFormDialog'
import { useService } from '@/hooks/useService'
import type { RestaurantTableType, ServiceItem } from '@/types/service'

/** Portado de ServiceItemsPage (apps/konekto_portal/lib/features/services/service_items_page.dart). */
export default function ServiceItemsPage({ params }: { params: Promise<{ serviceId: string }> }) {
  const { serviceId } = use(params)
  const {
    service,
    isLoading,
    error,
    createItem,
    updateItem,
    deleteItem,
    createTableType,
    updateTableType,
    deleteTableType,
  } = useService(serviceId)

  const [editingItem, setEditingItem] = useState<ServiceItem | null>(null)
  const [isCreatingItem, setIsCreatingItem] = useState(false)
  const [deletingItem, setDeletingItem] = useState<ServiceItem | null>(null)

  const [editingTableType, setEditingTableType] = useState<RestaurantTableType | null>(null)
  const [isCreatingTableType, setIsCreatingTableType] = useState(false)
  const [deletingTableType, setDeletingTableType] = useState<RestaurantTableType | null>(null)

  const [actionError, setActionError] = useState<string | null>(null)

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  if (!service) {
    const message = error instanceof Error ? error.message : 'Não foi possível carregar o serviço.'
    return <p className="text-[13.5px] text-cream">{message}</p>
  }

  const isItemDialogOpen = isCreatingItem || editingItem !== null
  const isTableTypeDialogOpen = isCreatingTableType || editingTableType !== null
  const errorMessage = actionError ?? (error instanceof Error ? error.message : null)

  async function handleConfirmDeleteItem() {
    if (!deletingItem) return
    setActionError(null)
    try {
      await deleteItem(deletingItem.id)
      setDeletingItem(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao remover item.')
      setDeletingItem(null)
    }
  }

  async function handleConfirmDeleteTableType() {
    if (!deletingTableType) return
    setActionError(null)
    try {
      await deleteTableType(deletingTableType.id)
      setDeletingTableType(null)
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Falha ao remover tipo de mesa.')
      setDeletingTableType(null)
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-2">
        <Link href="/settings/services" aria-label="Voltar" className="text-slate">
          ←
        </Link>
        <h1 className="flex-1 text-lg font-bold text-cream">{service.name}</h1>
        <button
          type="button"
          onClick={() => setIsCreatingItem(true)}
          className="text-[12.5px] font-semibold text-gold-light"
        >
          + Adicionar item
        </button>
      </div>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      {service.type === 'restaurant' && (
        <>
          <TableTypesSection
            tableTypes={service.tableTypes}
            onAdd={() => setIsCreatingTableType(true)}
            onEdit={setEditingTableType}
            onRemove={setDeletingTableType}
          />
          <RestaurantOperationsPanel serviceId={service.id} tableTypes={service.tableTypes} />
        </>
      )}

      <div className="rounded-2xl border border-border-strong bg-surface">
        {service.items.length === 0 ? (
          <p className="p-5 text-[12.5px] text-slate">Nenhum item nesse serviço ainda.</p>
        ) : (
          <div className="divide-y divide-border-strong">
            {service.items.map((item) => (
              <ItemRow
                key={item.id}
                item={item}
                onEdit={() => setEditingItem(item)}
                onRemove={() => setDeletingItem(item)}
              />
            ))}
          </div>
        )}
      </div>

      {isItemDialogOpen && (
        <ServiceItemFormDialog
          existing={editingItem}
          serviceType={service.type}
          onClose={() => {
            setIsCreatingItem(false)
            setEditingItem(null)
          }}
          onSubmit={async (item) => {
            if (editingItem) {
              await updateItem({ itemId: editingItem.id, item })
              setEditingItem(null)
            } else {
              await createItem(item)
              setIsCreatingItem(false)
            }
          }}
        />
      )}

      {isTableTypeDialogOpen && (
        <TableTypeFormDialog
          existing={editingTableType}
          onClose={() => {
            setIsCreatingTableType(false)
            setEditingTableType(null)
          }}
          onSubmit={async (input) => {
            if (editingTableType) {
              await updateTableType({ tableTypeId: editingTableType.id, input })
              setEditingTableType(null)
            } else {
              await createTableType(input)
              setIsCreatingTableType(false)
            }
          }}
        />
      )}

      {deletingItem && (
        <Modal
          title="Remover item?"
          onClose={() => setDeletingItem(null)}
          footer={
            <>
              <button type="button" onClick={() => setDeletingItem(null)} className="text-sm text-slate">
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmDeleteItem} className="text-sm text-[#B3261E]">
                Remover
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">&ldquo;{deletingItem.name}&rdquo; será removido.</p>
        </Modal>
      )}

      {deletingTableType && (
        <Modal
          title="Remover tipo de mesa?"
          onClose={() => setDeletingTableType(null)}
          footer={
            <>
              <button type="button" onClick={() => setDeletingTableType(null)} className="text-sm text-slate">
                Cancelar
              </button>
              <button type="button" onClick={handleConfirmDeleteTableType} className="text-sm text-[#B3261E]">
                Remover
              </button>
            </>
          }
        >
          <p className="text-[13px] text-cream">
            &ldquo;{deletingTableType.label ?? `Mesa de ${deletingTableType.seats} lugares`}&rdquo; será removido.
          </p>
        </Modal>
      )}
    </div>
  )
}

function TableTypesSection({
  tableTypes,
  onAdd,
  onEdit,
  onRemove,
}: {
  tableTypes: RestaurantTableType[]
  onAdd: () => void
  onEdit: (tableType: RestaurantTableType) => void
  onRemove: (tableType: RestaurantTableType) => void
}) {
  return (
    <div className="rounded-2xl border border-border-strong bg-surface p-[18px]">
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-bold text-cream">Tipos de mesa</h2>
        <button type="button" onClick={onAdd} className="text-[12.5px] font-semibold text-gold-light">
          + Adicionar
        </button>
      </div>
      {tableTypes.length === 0 ? (
        <p className="mt-2 text-xs text-slate">Nenhum tipo de mesa cadastrado ainda.</p>
      ) : (
        <div className="mt-3 flex flex-col gap-2">
          {tableTypes.map((tableType) => (
            <div
              key={tableType.id}
              className="flex items-center gap-3 rounded-[10px] border border-border-strong px-3 py-2"
            >
              <p className="min-w-0 flex-1 truncate text-[13px] text-cream">
                {tableType.label ?? `Mesa de ${tableType.seats} lugares`} · {tableType.quantity}{' '}
                {tableType.quantity === 1 ? 'mesa' : 'mesas'} · {tableType.seats}{' '}
                {tableType.seats === 1 ? 'lugar' : 'lugares'}
              </p>
              <button type="button" aria-label="Editar" onClick={() => onEdit(tableType)} className="text-slate">
                ✎
              </button>
              <button type="button" aria-label="Remover" onClick={() => onRemove(tableType)} className="text-slate">
                🗑
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function ItemRow({ item, onEdit, onRemove }: { item: ServiceItem; onEdit: () => void; onRemove: () => void }) {
  const subtitleParts = [
    item.price != null ? `R$ ${item.price.toFixed(2)}` : 'Sob consulta',
    item.category,
    item.location,
    item.extraInfo,
  ].filter((part): part is string => Boolean(part))

  return (
    <div className="flex items-center gap-3 px-5 py-3">
      <div className="min-w-0 flex-1">
        <p className="truncate text-[13.5px] font-semibold text-cream">{item.name}</p>
        <p className="truncate text-xs text-slate">{subtitleParts.join(' · ')}</p>
      </div>
      <button type="button" aria-label="Editar" onClick={onEdit} className="shrink-0 text-slate">
        ✎
      </button>
      <button type="button" aria-label="Remover" onClick={onRemove} className="shrink-0 text-slate">
        🗑
      </button>
    </div>
  )
}
