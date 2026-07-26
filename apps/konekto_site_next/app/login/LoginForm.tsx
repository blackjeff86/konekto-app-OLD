"use client";

import { useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";

/**
 * Porta de `apps/konekto_site/login.html` — MESMO contrato de API, mesma
 * lógica de resolução de `PORTAL_URL` (local vs. produção) e mesmo
 * mapeamento de erro. Esta é a única tela de login real do produto; o
 * portal (`konekto_portal_next`) não tem formulário próprio, só recebe o
 * token via query string e valida contra a API.
 */
const API_BASE_URL = "https://konekto-api.vercel.app";

const ERROR_MESSAGES: Record<string, string> = {
  staff_not_found: "Esta conta não está associada a nenhum hotel. Contate o suporte.",
  invalid_token: "Sua sessão expirou. Entre novamente.",
};

function resolvePortalUrl(): string {
  const isLocal = ["localhost", "127.0.0.1"].includes(window.location.hostname);
  return isLocal ? "http://localhost:3001" : "https://konekto-portal.vercel.app";
}

export function LoginForm() {
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Se o portal redirecionou de volta por token inválido/expirado, mostra o motivo — derivado direto da URL, sem efeito.
  const redirectErrorParam = searchParams.get("error");
  const redirectError = redirectErrorParam ? ERROR_MESSAGES[redirectErrorParam] : undefined;
  const errorMessage = submitError ?? redirectError ?? null;

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), password }),
      });

      if (!response.ok) {
        setSubmitError("E-mail ou senha inválidos. Confira seus dados e tente novamente.");
        return;
      }

      const data = await response.json();
      window.location.href = `${resolvePortalUrl()}/?token=${encodeURIComponent(data.token)}`;
    } catch {
      setSubmitError("Não foi possível conectar ao servidor. Tente novamente em instantes.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="w-full max-w-[400px] rounded-3xl border border-border bg-surface p-[clamp(2rem,3vw,2.6rem)] shadow-[0_40px_80px_-32px_rgba(22,24,29,0.18)]">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/logo/sevvn-wordmark-light-bg.svg" alt="Sevvn" className="mx-auto mb-6 h-6 w-auto" />
      <span className="eyebrow mx-auto block justify-center text-center">Área do hotel</span>
      <h1 className="mt-[0.6rem] text-center text-[1.6rem] font-extrabold tracking-[-0.02em] text-ink">
        Bem-vindo(a) de volta
      </h1>
      <p className="mb-7 mt-1 text-center text-[0.88rem] text-muted">
        Entre para gerenciar hóspedes, pedidos e a experiência do seu hotel.
      </p>

      {errorMessage ? (
        <div className="mb-[1.1rem] rounded-[10px] border border-red-600/25 bg-red-600/[0.08] px-[0.8rem] py-[0.65rem] text-[0.82rem] text-[#B42318]">
          {errorMessage}
        </div>
      ) : null}

      <form onSubmit={handleSubmit} noValidate>
        <div className="mb-[1.1rem]">
          <label htmlFor="email" className="mb-[0.4rem] block text-[0.78rem] font-semibold text-muted">
            E-mail corporativo
          </label>
          <div className="flex items-center gap-[0.55rem] rounded-xl border-[1.2px] border-border-strong bg-surface-alt px-[0.85rem] py-[0.7rem] focus-within:border-primary focus-within:shadow-[0_0_0_3px_var(--color-primary-soft)]">
            <input
              id="email"
              type="email"
              required
              autoComplete="username"
              placeholder="voce@seuhotel.com"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="w-full border-none bg-transparent text-[0.95rem] text-ink outline-none placeholder:text-muted-soft"
            />
          </div>
        </div>
        <div className="mb-[1.1rem]">
          <label htmlFor="password" className="mb-[0.4rem] block text-[0.78rem] font-semibold text-muted">
            Senha
          </label>
          <div className="flex items-center gap-[0.55rem] rounded-xl border-[1.2px] border-border-strong bg-surface-alt px-[0.85rem] py-[0.7rem] focus-within:border-primary focus-within:shadow-[0_0_0_3px_var(--color-primary-soft)]">
            <input
              id="password"
              type="password"
              required
              autoComplete="current-password"
              placeholder="••••••••"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full border-none bg-transparent text-[0.95rem] text-ink outline-none placeholder:text-muted-soft"
            />
          </div>
        </div>

        <div className="mb-[1.4rem] mt-[-0.3rem] flex items-center justify-between">
          <label className="flex items-center gap-[0.45rem] text-[0.82rem] text-muted">
            <input type="checkbox" className="accent-primary" /> Lembrar de mim
          </label>
          <a href="#" className="text-[0.82rem] font-semibold text-primary hover:text-ink">
            Esqueci minha senha
          </a>
        </div>

        <button
          type="submit"
          disabled={isSubmitting}
          className="flex w-full items-center justify-center gap-2 rounded-full bg-primary py-[0.9rem] text-[0.92rem] font-bold tracking-[0.02em] text-on-primary transition-[transform,opacity] duration-200 hover:-translate-y-px hover:opacity-90 disabled:translate-y-0 disabled:cursor-default disabled:opacity-60"
        >
          {isSubmitting ? "Entrando..." : "Entrar no painel"}
        </button>
      </form>

      <div className="my-6 flex items-center gap-[0.8rem] text-[0.78rem] text-muted-soft before:h-px before:flex-1 before:bg-border-strong before:content-[''] after:h-px after:flex-1 after:bg-border-strong after:content-['']">
        novo por aqui
      </div>
      <p className="text-center text-[0.82rem] leading-[1.6] text-muted">
        Ainda não é cliente Sevvn?
        <br />
        <Link href="/#contato" className="font-semibold text-primary hover:text-ink">
          Fale com a gente
        </Link>{" "}
        e coloque seu hotel no ar.
      </p>
    </div>
  );
}
