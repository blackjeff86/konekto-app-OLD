"use client"

import { useState } from "react"
import { useEffect } from "react"

type FormKind = "hotel" | "partner" | "enterprise"

const INITIAL_STATE = {
  name: "",
  email: "",
  phone: "",
  company: "",
  city: "",
  message: "",
  category: "",
  units: "",
  rooms: "",
  pms: "",
  interest: "",
  website: "",
  consent: "",
  honey: "",
}

async function submitContact(kind: FormKind, payload: Record<string, string>) {
  const response = await fetch("/api/contact", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ kind, payload }),
  })

  const body = (await response.json()) as { error?: string; message?: string }
  if (!response.ok) {
    throw new Error(body.error ?? "Não foi possível enviar seu contato agora.")
  }
  return body.message ?? "Recebemos seu contato."
}

export function ContactForms() {
  const [kind, setKind] = useState<FormKind>("hotel")
  const [form, setForm] = useState(INITIAL_STATE)
  const [status, setStatus] = useState<"idle" | "sending" | "sent" | "error">("idle")
  const [feedback, setFeedback] = useState("")

  useEffect(() => {
    function syncKindFromHash() {
      const hash = window.location.hash
      if (hash === "#partner-interest") {
        setKind("partner")
        return
      }
      if (hash === "#enterprise") {
        setKind("enterprise")
        return
      }
      setKind("hotel")
    }

    syncKindFromHash()
    window.addEventListener("hashchange", syncKindFromHash)
    return () => window.removeEventListener("hashchange", syncKindFromHash)
  }, [])

  function updateField(field: keyof typeof INITIAL_STATE, value: string) {
    setForm((current) => ({ ...current, [field]: value }))
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setStatus("sending")
    setFeedback("")
    try {
      const message = await submitContact(kind, form)
      setStatus("sent")
      setFeedback(message)
      setForm(INITIAL_STATE)
    } catch (error) {
      setStatus("error")
      setFeedback(error instanceof Error ? error.message : "Falha ao enviar.")
    }
  }

  return (
    <div className="rounded-[28px] border border-border bg-white p-7 shadow-[0_24px_70px_-48px_rgba(22,24,29,0.24)]">
      <div className="flex flex-wrap gap-2">
        {[
          { id: "hotel" as const, label: "Demonstração para hotéis" },
          { id: "partner" as const, label: "Interesse de parceiros" },
          { id: "enterprise" as const, label: "Rede ou grande operação" },
        ].map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setKind(tab.id)}
            className={`rounded-full px-4 py-2 text-[0.82rem] font-semibold ${
              kind === tab.id ? "bg-ink text-white" : "bg-card text-muted"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        <input
          type="text"
          tabIndex={-1}
          autoComplete="off"
          value={form.honey}
          onChange={(e) => updateField("honey", e.target.value)}
          className="hidden"
          aria-hidden="true"
        />
        <div className="grid gap-4 md:grid-cols-2">
          <Field label="Nome">
            <input value={form.name} onChange={(e) => updateField("name", e.target.value)} required className={INPUT_CLASS} />
          </Field>
          <Field label="E-mail">
            <input type="email" value={form.email} onChange={(e) => updateField("email", e.target.value)} required className={INPUT_CLASS} />
          </Field>
          <Field label="Telefone">
            <input value={form.phone} onChange={(e) => updateField("phone", e.target.value)} className={INPUT_CLASS} />
          </Field>
          <Field label={kind === "enterprise" ? "Grupo ou empresa" : "Empresa"}>
            <input value={form.company} onChange={(e) => updateField("company", e.target.value)} required className={INPUT_CLASS} />
          </Field>
          {kind !== "enterprise" ? (
            <>
              <Field label="Cidade / região">
                <input value={form.city} onChange={(e) => updateField("city", e.target.value)} className={INPUT_CLASS} />
              </Field>
              <Field label={kind === "partner" ? "Categoria" : "Tipo de empreendimento"}>
                <input
                  value={kind === "partner" ? form.category : form.interest}
                  onChange={(e) =>
                    updateField(kind === "partner" ? "category" : "interest", e.target.value)
                  }
                  className={INPUT_CLASS}
                />
              </Field>
            </>
          ) : (
            <>
              <Field label="Quantidade de unidades">
                <input value={form.units} onChange={(e) => updateField("units", e.target.value)} className={INPUT_CLASS} />
              </Field>
              <Field label="Quantidade aproximada de quartos">
                <input value={form.rooms} onChange={(e) => updateField("rooms", e.target.value)} className={INPUT_CLASS} />
              </Field>
            </>
          )}
          {kind === "hotel" ? (
            <>
              <Field label="PMS utilizado">
                <input value={form.pms} onChange={(e) => updateField("pms", e.target.value)} className={INPUT_CLASS} />
              </Field>
              <Field label="Interesse principal">
                <input value={form.interest} onChange={(e) => updateField("interest", e.target.value)} className={INPUT_CLASS} />
              </Field>
            </>
          ) : null}
          {kind === "partner" ? (
            <Field label="Site ou Instagram" className="md:col-span-2">
              <input value={form.website} onChange={(e) => updateField("website", e.target.value)} className={INPUT_CLASS} />
            </Field>
          ) : null}
        </div>
        <Field label="Mensagem">
          <textarea
            value={form.message}
            onChange={(e) => updateField("message", e.target.value)}
            rows={5}
            required
            className={`${INPUT_CLASS} min-h-[132px] resize-y`}
          />
        </Field>

        <label className="flex items-start gap-3 rounded-[16px] border border-border bg-surface-alt px-4 py-3 text-[0.85rem] leading-[1.6] text-muted">
          <input
            type="checkbox"
            required
            checked={form.consent === "yes"}
            onChange={(e) => updateField("consent", e.target.checked ? "yes" : "")}
            className="mt-1 accent-primary"
          />
          <span>
            Concordo em compartilhar meus dados para que a equipe da Sevvn entre em contato sobre
            demonstração, parceria ou operação Enterprise.
          </span>
        </label>

        {feedback ? (
          <div
            className={`rounded-[14px] px-4 py-3 text-[0.88rem] ${
              status === "sent"
                ? "border border-[#13733333] bg-[#EAF8EF] text-[#137333]"
                : "border border-[#B4231833] bg-[#FDECEC] text-[#B42318]"
            }`}
          >
            {feedback}
          </div>
        ) : null}

        <button
          type="submit"
          disabled={status === "sending"}
          className="rounded-[12px] bg-primary px-6 py-3 text-[0.94rem] font-bold text-white disabled:opacity-60"
        >
          {status === "sending"
            ? "Enviando..."
            : kind === "partner"
              ? "Enviar interesse de parceria"
              : kind === "enterprise"
                ? "Falar sobre operação Enterprise"
                : "Agendar demonstração"}
        </button>
      </form>
    </div>
  )
}

function Field({
  label,
  children,
  className,
}: {
  label: string
  children: React.ReactNode
  className?: string
}) {
  return (
    <label className={`block text-[0.82rem] font-medium text-ink ${className ?? ""}`}>
      <span className="mb-2 block">{label}</span>
      {children}
    </label>
  )
}

const INPUT_CLASS =
  "block w-full rounded-[14px] border border-border bg-surface-alt px-4 py-3 text-[0.94rem] text-ink outline-none transition focus:border-primary"
