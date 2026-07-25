/** Portado de apps/konekto_portal/lib/data/integration_repository.dart. */
export interface IntegrationStatus {
  configured: boolean
  apiKeyPrefix: string | null
  webhookUrl: string | null
  enabled: boolean
  lastInboundSyncAt: string | null
  lastOutboundAt: string | null
  lastOutboundOk: boolean | null
}
