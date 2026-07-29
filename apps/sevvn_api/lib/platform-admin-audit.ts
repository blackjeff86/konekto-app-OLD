import type { Prisma } from '@/app/generated/prisma/client'
import type { PlatformAdminTokenPayload } from '@/lib/platform-auth'
import { buildRequestContext } from '@/lib/request-context'
import type { NextRequest } from 'next/server'

interface AuditWriter {
  platformAdminAuditLog: {
    create(args: { data: Prisma.PlatformAdminAuditLogUncheckedCreateInput }): Promise<unknown>
  }
}

interface RecordPlatformAdminAuditInput {
  action: string
  admin: PlatformAdminTokenPayload
  payload?: Prisma.InputJsonValue
  request: NextRequest
  targetId?: string
  targetType: string
  hotelId?: string
}

export async function recordPlatformAdminAudit(
  writer: AuditWriter,
  { action, admin, payload, request, targetId, targetType, hotelId }: RecordPlatformAdminAuditInput,
) {
  const context = buildRequestContext(request)

  await writer.platformAdminAuditLog.create({
    data: {
      action,
      adminEmail: admin.email,
      adminId: admin.sub,
      clientIp: context.clientIp,
      correlationId: context.correlationId,
      hotelId,
      payload,
      targetId,
      targetType,
    },
  })
}
