-- CreateEnum
CREATE TYPE "HotelKind" AS ENUM ('template', 'client');

-- AlterTable
ALTER TABLE "hotels" ADD COLUMN     "kind" "HotelKind" NOT NULL DEFAULT 'client';

-- Backfill: os dois hotéis de demonstração existentes (Verde Pousada,
-- Amara Bay) são modelos de infraestrutura visual, não clientes reais.
UPDATE "hotels" SET "kind" = 'template' WHERE "id" IN ('hotel_1', 'hotel_2');
