-- AlterTable: adiciona nullable primeiro (backfill vem antes de travar NOT NULL)
ALTER TABLE "services" ADD COLUMN "category" TEXT;

-- Backfill: cada serviço existente ganha a categoria com o mesmo nome que
-- a seção fixa que ele já ocupava na lista do portal — nenhuma mudança
-- visual pra quem já tinha serviços criados.
UPDATE "services" SET "category" = 'Serviço de Quarto' WHERE "type" = 'room_service';
UPDATE "services" SET "category" = 'Restaurante' WHERE "type" = 'restaurant';
UPDATE "services" SET "category" = 'Passeio / Atividade' WHERE "type" = 'activity';

ALTER TABLE "services" ALTER COLUMN "category" SET NOT NULL;
