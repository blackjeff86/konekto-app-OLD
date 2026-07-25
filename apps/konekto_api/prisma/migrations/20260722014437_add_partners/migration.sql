-- CreateEnum
CREATE TYPE "PaymentMode" AS ENUM ('hotel', 'partner');

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "partnerName" TEXT,
ADD COLUMN     "paymentMode" "PaymentMode" NOT NULL DEFAULT 'hotel';

-- AlterTable
ALTER TABLE "service_items" ADD COLUMN     "partnerId" TEXT,
ADD COLUMN     "paymentMode" "PaymentMode" NOT NULL DEFAULT 'hotel';

-- CreateTable
CREATE TABLE "partners" (
    "id" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "contactName" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "partners_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "partners_hotelId_idx" ON "partners"("hotelId");

-- CreateIndex
CREATE INDEX "service_items_partnerId_idx" ON "service_items"("partnerId");

-- AddForeignKey
ALTER TABLE "service_items" ADD CONSTRAINT "service_items_partnerId_fkey" FOREIGN KEY ("partnerId") REFERENCES "partners"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partners" ADD CONSTRAINT "partners_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
