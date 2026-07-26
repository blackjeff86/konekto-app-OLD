import type { Metadata } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Sevvn — A infraestrutura digital da hospitalidade moderna",
  description:
    "Sevvn é a plataforma modular por trás do aplicativo do seu hotel — planos, templates e módulos reais que crescem junto com a operação, sempre com a marca do seu hotel, nunca a nossa.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="pt-BR"
      className={`${inter.variable} ${jetbrainsMono.variable} antialiased`}
      style={{ colorScheme: "light" }}
    >
      <body className="min-h-screen bg-bg text-ink">{children}</body>
    </html>
  );
}
