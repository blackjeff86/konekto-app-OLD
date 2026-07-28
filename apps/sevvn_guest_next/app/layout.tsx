import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Sevvn Guest",
  description: "Nova base TypeScript do app do hospede da Sevvn.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
