/** Portado de apps/konekto_portal/lib/models/partner.dart. */
export interface Partner {
  id: string
  name: string
  contactName: string | null
  phone: string | null
  email: string | null
  notes: string | null
}

/** Dados do formulário de criação/edição de um parceiro. */
export interface PartnerInput {
  name: string
  contactName?: string | null
  phone?: string | null
  email?: string | null
  notes?: string | null
}
