-- Habilita gen_random_uuid() pro backfill abaixo (Neon já traz pgcrypto disponível).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- CreateEnum
CREATE TYPE "StayStatus" AS ENUM ('active', 'closed');

-- CreateTable
CREATE TABLE "stays" (
    "id" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "roomNumber" TEXT NOT NULL,
    "checkInDate" TIMESTAMP(3) NOT NULL,
    "checkOutDate" TIMESTAMP(3) NOT NULL,
    "status" "StayStatus" NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stays_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stay_notices" (
    "id" TEXT NOT NULL,
    "stayId" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stay_notices_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stays_hotelId_idx" ON "stays"("hotelId");

-- CreateIndex
CREATE INDEX "stay_notices_stayId_idx" ON "stay_notices"("stayId");

-- AddForeignKey
ALTER TABLE "stays" ADD CONSTRAINT "stays_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stay_notices" ADD CONSTRAINT "stay_notices_stayId_fkey" FOREIGN KEY ("stayId") REFERENCES "stays"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AlterTable: adiciona stayId nullable primeiro (backfill vem antes de travar NOT NULL)
ALTER TABLE "guests" ADD COLUMN "stayId" TEXT;

-- Backfill: uma Stay por Guest já existente (nenhum quarto compartilhado hoje em produção),
-- preservando exatamente o roomNumber/checkInDate/checkOutDate que cada guest já tinha.
DO $$
DECLARE
  g RECORD;
  new_stay_id TEXT;
BEGIN
  FOR g IN SELECT "id", "hotelId", "roomNumber", "checkInDate", "checkOutDate" FROM "guests" LOOP
    new_stay_id := gen_random_uuid()::text;
    INSERT INTO "stays" ("id", "hotelId", "roomNumber", "checkInDate", "checkOutDate", "status", "createdAt", "updatedAt")
    VALUES (new_stay_id, g."hotelId", g."roomNumber", g."checkInDate", g."checkOutDate", 'active', now(), now());
    UPDATE "guests" SET "stayId" = new_stay_id WHERE "id" = g."id";
  END LOOP;
END $$;

-- Agora que todo Guest existente tem stayId preenchido, trava como obrigatório
-- e remove os campos que passaram a viver só em Stay.
ALTER TABLE "guests" ALTER COLUMN "stayId" SET NOT NULL;
ALTER TABLE "guests" DROP COLUMN "roomNumber",
DROP COLUMN "checkInDate",
DROP COLUMN "checkOutDate";

-- CreateIndex
CREATE INDEX "guests_stayId_idx" ON "guests"("stayId");

-- AddForeignKey
ALTER TABLE "guests" ADD CONSTRAINT "guests_stayId_fkey" FOREIGN KEY ("stayId") REFERENCES "stays"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
