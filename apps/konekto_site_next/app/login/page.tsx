import { Suspense } from "react";
import { LoginForm } from "./LoginForm";
import { Logo } from "@/components/ui/Logo";

export const metadata = {
  title: "Entrar — Sevvn",
  description: "Área do hotel Sevvn — acesse o painel de gestão do seu hotel.",
};

export default function LoginPage() {
  return (
    <div className="flex min-h-screen flex-col">
      <div className="p-6">
        <Logo />
      </div>
      <main className="flex flex-1 items-center justify-center p-6">
        <Suspense>
          <LoginForm />
        </Suspense>
      </main>
      <footer className="p-6 text-center text-[0.76rem] text-muted-soft">
        Precisa de ajuda?{" "}
        <a href="mailto:suporte@konekto.app" className="text-primary">
          suporte@konekto.app
        </a>
      </footer>
    </div>
  );
}
