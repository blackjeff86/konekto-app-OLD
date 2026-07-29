-- CreateEnum
CREATE TYPE "ServiceType" AS ENUM ('room_service', 'restaurant', 'activity');

-- AlterTable: adiciona nullable primeiro (backfill vem antes de travar NOT NULL)
ALTER TABLE "services" ADD COLUMN "type" "ServiceType";

-- Backfill a partir do slug/icon já existentes — mesmo critério que o app
-- do hóspede já usava client-side (slug 'room-service' -> room_service,
-- icon 'restaurant' -> restaurant, resto -> activity).
UPDATE "services" SET "type" = 'room_service' WHERE "slug" = 'room-service';
UPDATE "services" SET "type" = 'restaurant' WHERE "icon" = 'restaurant' AND "type" IS NULL;
UPDATE "services" SET "type" = 'activity' WHERE "type" IS NULL;

ALTER TABLE "services" ALTER COLUMN "type" SET NOT NULL;

-- AlterTable: item técnico/oculto (ex: "Reserva de mesa" de um restaurante)
ALTER TABLE "service_items" ADD COLUMN "hidden" BOOLEAN NOT NULL DEFAULT false;
