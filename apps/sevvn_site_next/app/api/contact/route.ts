import { NextResponse } from "next/server"

type ContactKind = "hotel" | "partner" | "enterprise"

interface ContactPayload {
  kind?: ContactKind
  payload?: Record<string, string>
}

export async function POST(request: Request) {
  const body = (await request.json().catch(() => null)) as ContactPayload | null
  if (!body?.kind || !body.payload) {
    return NextResponse.json({ error: "Requisição inválida." }, { status: 400 })
  }

  const { kind, payload } = body
  if (payload.honey?.trim()) {
    return NextResponse.json({ message: "Recebemos seu contato." })
  }
  if (!payload.name?.trim() || !payload.email?.trim() || !payload.company?.trim() || !payload.message?.trim()) {
    return NextResponse.json({ error: "Preencha os campos obrigatórios antes de enviar." }, { status: 400 })
  }
  if (payload.consent?.trim() !== "yes") {
    return NextResponse.json({ error: "Precisamos do seu consentimento para registrar o contato." }, { status: 400 })
  }

  const normalized = {
    kind,
    submittedAt: new Date().toISOString(),
    payload: Object.fromEntries(
      Object.entries(payload)
        .filter(([key]) => key !== "honey")
        .map(([key, value]) => [key, value.trim()]),
    ),
  }

  console.info("[sevvn-contact-lead]", JSON.stringify(normalized))

  return NextResponse.json({
    message:
      "Recebemos seu contato. Nossa equipe retorna pelos canais informados para continuar a conversa.",
  })
}
