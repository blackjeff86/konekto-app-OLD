-- Habilita gen_random_uuid() pro backfill abaixo (já usado em migrations anteriores).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- CreateTable
CREATE TABLE "rooms" (
    "id" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rooms_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "rooms_hotelId_idx" ON "rooms"("hotelId");

-- CreateIndex
CREATE UNIQUE INDEX "rooms_hotelId_number_key" ON "rooms"("hotelId", "number");

-- AddForeignKey
ALTER TABLE "rooms" ADD CONSTRAINT "rooms_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AlterTable: adiciona roomId nullable primeiro (backfill vem antes de travar NOT NULL)
ALTER TABLE "stays" ADD COLUMN "roomId" TEXT;

-- Backfill: um Room por par (hotelId, roomNumber) distinto já usado em
-- alguma Stay — preserva o número exato que já existia, sem duplicar
-- quarto pra estadias diferentes do mesmo número.
DO $$
DECLARE
  r RECORD;
  new_room_id TEXT;
BEGIN
  FOR r IN SELECT DISTINCT "hotelId", "roomNumber" FROM "stays" LOOP
    new_room_id := gen_random_uuid()::text;
    INSERT INTO "rooms" ("id", "hotelId", "number", "createdAt", "updatedAt")
    VALUES (new_room_id, r."hotelId", r."roomNumber", now(), now());
    UPDATE "stays" SET "roomId" = new_room_id WHERE "hotelId" = r."hotelId" AND "roomNumber" = r."roomNumber";
  END LOOP;
END $$;

-- Agora que toda Stay existente tem roomId preenchido, trava como
-- obrigatório e remove o campo que passou a viver só em Room.
ALTER TABLE "stays" ALTER COLUMN "roomId" SET NOT NULL;
ALTER TABLE "stays" DROP COLUMN "roomNumber";

-- CreateIndex
CREATE INDEX "stays_roomId_idx" ON "stays"("roomId");

-- AddForeignKey
ALTER TABLE "stays" ADD CONSTRAINT "stays_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "rooms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
