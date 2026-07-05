# konekto_api

Backend de API do Konekto — Next.js (App Router, só rotas de API) + Prisma + Neon (Postgres serverless). Substitui o Firebase/Firestore usado anteriormente pelo app do hóspede e pelo portal do hotel.

## Setup

1. Crie um projeto em [neon.tech](https://neon.tech) e copie a connection string (a que tem `-pooler` no host).
2. `cp .env.example .env` e preencha:
   - `DATABASE_URL` — a connection string do Neon.
   - `JWT_SECRET` — uma string aleatória longa (`openssl rand -base64 48`).
3. `npm install`
4. `npx prisma migrate dev --name init` — cria as tabelas no Neon.
5. `npm run db:seed` — popula `hotel_1`/`hotel_2` a partir de `prisma/seed-data/` e cria uma conta de staff de teste:
   - E-mail: `gerente.teste@konekto.app`
   - Senha: `konekto123`
6. `npm run dev` — sobe em `http://localhost:3000`.

## Endpoints

Públicos (sem autenticação):
- `GET /api/health`
- `GET /api/hotels`
- `GET /api/hotels/:hotelId`
- `GET /api/hotels/:hotelId/content/:docName`
- `GET /api/promotions`

Staff (JWT):
- `POST /api/auth/login` — `{email, password}` → `{token, staff}`
- `GET /api/auth/me` — header `Authorization: Bearer <token>` → `{staff}`

## Deploy (Vercel)

Root Directory do projeto Vercel = `apps/konekto_api`. Configurar as env vars (`DATABASE_URL`, `JWT_SECRET`, opcionalmente `ALLOWED_ORIGINS`) no dashboard. Rodar `npm run prisma:deploy` manualmente contra a connection string de produção quando houver novas migrations (não integrado ao build da Vercel, pra evitar corridas concorrentes entre deploys).

## Prisma Studio

`npm run prisma:studio` — navegador visual pro banco, substitui o antigo hábito de clicar no Console do Firebase.
