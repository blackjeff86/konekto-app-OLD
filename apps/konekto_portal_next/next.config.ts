import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Indicador de rota do Next.js (o círculo preto "N" no canto inferior
  // esquerdo) só aparece em `next dev`, nunca em produção — desligado aqui
  // porque sobrepunha o nome do usuário na sidebar durante testes locais.
  devIndicators: false,
};

export default nextConfig;
