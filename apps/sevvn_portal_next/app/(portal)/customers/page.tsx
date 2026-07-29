'use client'

import { useMemo, useState } from 'react'
import Link from 'next/link'
import { useCustomers } from '@/hooks/useCustomers'
import { customerFullName, type Customer } from '@/types/customer'
import { formatDate } from '@/lib/utils/date'

function currency(value: number): string {
  return `R$ ${value.toFixed(2)}`
}

type SortMode = 'lastVisit' | 'totalSpent' | 'visitsCount' | 'name'

const SORT_LABEL: Record<SortMode, string> = {
  lastVisit: 'Última visita',
  totalSpent: 'Total gasto',
  visitsCount: 'Visitas',
  name: 'Nome',
}

function sortCustomers(customers: Customer[], mode: SortMode): Customer[] {
  const sorted = [...customers]
  switch (mode) {
    case 'lastVisit':
      return sorted.sort((a, b) => new Date(b.lastVisit).getTime() - new Date(a.lastVisit).getTime())
    case 'totalSpent':
      return sorted.sort((a, b) => b.totalSpent - a.totalSpent)
    case 'visitsCount':
      return sorted.sort((a, b) => b.visitsCount - a.visitsCount)
    case 'name':
      return sorted.sort((a, b) => customerFullName(a).localeCompare(customerFullName(b)))
  }
}

/** Portado de apps/konekto_portal/lib/features/customers/customers_page.dart. */
export default function CustomersPage() {
  const { customers, isLoading, error } = useCustomers()
  const [search, setSearch] = useState('')
  const [sortMode, setSortMode] = useState<SortMode>('lastVisit')

  const visibleCustomers = useMemo(() => {
    const query = search.trim().toLowerCase()
    const filtered = query
      ? customers.filter(
          (customer) =>
            customerFullName(customer).toLowerCase().includes(query) ||
            customer.documentNumber.toLowerCase().includes(query),
        )
      : customers
    return sortCustomers(filtered, sortMode)
  }, [customers, search, sortMode])

  if (isLoading) {
    return (
      <div className="flex justify-center py-10">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-gold border-t-transparent" />
      </div>
    )
  }

  const errorMessage = error instanceof Error ? error.message : null

  return (
    <div className="flex flex-col gap-7">
      <p className="max-w-xl text-[13.5px] leading-relaxed text-slate">
        Todo mundo que já se hospedou, com o histórico completo de estadias e o total gasto — base
        pra futuras campanhas de e-mail e cupons.
      </p>

      {errorMessage && (
        <div className="rounded-[10px] border border-[#DC262680] bg-[#DC26261A] px-3 py-2.5 text-[12.5px] text-[#B3261E]">
          {errorMessage}
        </div>
      )}

      <div className="flex gap-3">
        <input
          type="text"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder="Buscar por nome ou documento..."
          className="flex-1 rounded-xl border border-border-strong bg-surface px-4 py-3 text-[13.5px] text-cream outline-none focus:border-gold"
        />
        <select
          value={sortMode}
          onChange={(event) => setSortMode(event.target.value as SortMode)}
          className="shrink-0 rounded-xl border border-border-strong bg-surface px-4 py-3 text-[12.5px] text-cream outline-none focus:border-gold"
        >
          {(Object.keys(SORT_LABEL) as SortMode[]).map((mode) => (
            <option key={mode} value={mode}>
              Ordenar: {SORT_LABEL[mode]}
            </option>
          ))}
        </select>
      </div>

      {visibleCustomers.length === 0 ? (
        <div className="whisper-shadow rounded-xl border border-border bg-surface p-7 text-[13.5px] text-cream">
          {customers.length === 0 ? 'Nenhum cliente no histórico ainda.' : 'Nenhum resultado pra essa busca.'}
        </div>
      ) : (
        <div className="whisper-shadow hairline-divide overflow-hidden rounded-xl border border-border bg-surface">
          {visibleCustomers.map((customer) => (
            <Link
              key={customer.documentNumber}
              href={`/customers/${customer.documentNumber}`}
              className="flex items-center gap-4 px-7 py-5 transition-colors hover:bg-surface-alt"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-cream">{customerFullName(customer)}</p>
                <p className="mt-0.5 truncate text-xs text-slate">
                  {customer.email ?? `${customer.phoneCountryCode} ${customer.phoneNumber}`}
                </p>
              </div>
              <span className="shrink-0 rounded-full bg-gold/10 px-3 py-1 text-[10px] font-bold tracking-wide text-gold-light uppercase">
                {customer.visitsCount} visita{customer.visitsCount === 1 ? '' : 's'}
              </span>
              <span className="w-[90px] shrink-0 text-right text-[13px] font-semibold text-cream">
                {currency(customer.totalSpent)}
              </span>
              <span className="w-20 shrink-0 text-right text-xs text-slate">
                {formatDate(customer.lastVisit)}
              </span>
              <span className="shrink-0 text-slate-soft">›</span>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
