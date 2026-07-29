import type { Metadata } from "next"
import { Inter, JetBrains_Mono } from "next/font/google"
import { BRAND } from "@/content/brand"
import "./globals.css"

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: BRAND.title,
  description: BRAND.shortDescription,
  openGraph: {
    title: BRAND.title,
    description: BRAND.shortDescription,
    siteName: BRAND.name,
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: BRAND.title,
    description: BRAND.shortDescription,
  },
}

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
  )
}
