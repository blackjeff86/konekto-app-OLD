import type { Metadata } from "next";
import {
  Libre_Caslon_Text,
  Plus_Jakarta_Sans,
  Work_Sans,
} from "next/font/google";
import "./globals.css";

const auraDisplay = Libre_Caslon_Text({
  variable: "--font-aura-display",
  subsets: ["latin"],
  weight: "400",
});

const auraHeading = Plus_Jakarta_Sans({
  variable: "--font-aura-heading",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
});

const auraBody = Work_Sans({
  variable: "--font-aura-body",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

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
      <body
        className={`${auraDisplay.variable} ${auraHeading.variable} ${auraBody.variable}`}
      >
        {children}
      </body>
    </html>
  );
}
