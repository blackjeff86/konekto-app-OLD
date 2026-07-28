import { NextRequest, NextResponse } from 'next/server'
import { buildRequestContext, ensureResponseHasCorrelationId, type RequestContext } from '@/lib/request-context'

interface RequestLogOptions {
  route: string
  surface: string
}

type RequestHandler = (context: RequestContext) => Promise<Response> | Response

function logStructured(level: 'info' | 'error', payload: Record<string, unknown>) {
  const serialized = JSON.stringify(payload)
  if (level === 'error') {
    console.error(serialized)
    return
  }
  console.info(serialized)
}

export async function withRequestLogging(
  request: NextRequest,
  options: RequestLogOptions,
  handler: RequestHandler,
): Promise<NextResponse> {
  const context = buildRequestContext(request)
  const startedAt = Date.now()

  try {
    const response = ensureResponseHasCorrelationId(await handler(context), context.correlationId)
    logStructured('info', {
      event: 'api_request_completed',
      correlationId: context.correlationId,
      clientIp: context.clientIp,
      durationMs: Date.now() - startedAt,
      method: context.method,
      path: context.pathname,
      route: options.route,
      status: response.status,
      surface: options.surface,
    })
    return response
  } catch (error) {
    const details =
      error instanceof Error
        ? { errorMessage: error.message, errorName: error.name }
        : { errorMessage: 'unknown_error', errorName: typeof error }

    logStructured('error', {
      event: 'api_request_failed',
      correlationId: context.correlationId,
      clientIp: context.clientIp,
      durationMs: Date.now() - startedAt,
      method: context.method,
      path: context.pathname,
      route: options.route,
      surface: options.surface,
      ...details,
    })
    throw error
  }
}
