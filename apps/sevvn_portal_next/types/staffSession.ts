/** Portado de apps/konekto_portal/lib/auth/staff_role.dart + staff_session.dart. */
export type StaffRole = 'gerente' | 'recepcao'

export interface StaffSession {
  uid: string
  hotelId: string
  role: StaffRole
  name: string
  email: string
}

interface StaffSessionJson {
  id: string
  hotelId: string
  role: string
  name?: string | null
  email?: string | null
}

export function staffSessionFromJson(json: StaffSessionJson): StaffSession {
  return {
    uid: json.id,
    hotelId: json.hotelId,
    role: json.role as StaffRole,
    name: json.name ?? '',
    email: json.email ?? '',
  }
}

export const staffRoleLabel: Record<StaffRole, string> = {
  gerente: 'Gerente',
  recepcao: 'Recepção',
}
