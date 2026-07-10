/*
  Warnings:

  - You are about to drop the column `name` on the `guests` table. All the data in the column will be lost.
  - Added the required column `checkInDate` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `checkOutDate` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `country` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `documentNumber` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `documentType` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `firstName` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `lastName` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `phoneCountryCode` to the `guests` table without a default value. This is not possible if the table is not empty.
  - Added the required column `phoneNumber` to the `guests` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "DocumentType" AS ENUM ('cpf', 'passport', 'other');

-- AlterTable
ALTER TABLE "guests" DROP COLUMN "name",
ADD COLUMN     "address" TEXT,
ADD COLUMN     "checkInDate" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "checkOutDate" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "country" TEXT NOT NULL,
ADD COLUMN     "documentNumber" TEXT NOT NULL,
ADD COLUMN     "documentType" "DocumentType" NOT NULL,
ADD COLUMN     "email" TEXT,
ADD COLUMN     "firstName" TEXT NOT NULL,
ADD COLUMN     "lastName" TEXT NOT NULL,
ADD COLUMN     "phoneCountryCode" TEXT NOT NULL,
ADD COLUMN     "phoneNumber" TEXT NOT NULL,
ADD COLUMN     "whatsappCountryCode" TEXT,
ADD COLUMN     "whatsappNumber" TEXT,
ADD COLUMN     "wifiPassword" TEXT;
