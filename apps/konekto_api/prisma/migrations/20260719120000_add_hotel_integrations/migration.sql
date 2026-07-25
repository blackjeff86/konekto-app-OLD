-- AlterTable
ALTER TABLE "stays" ADD COLUMN     "externalId" TEXT;

-- AlterTable
ALTER TABLE "guests" ADD COLUMN     "externalId" TEXT;

-- AlterTable
ALTER TABLE "services" ADD COLUMN     "externalId" TEXT;

-- AlterTable
ALTER TABLE "service_items" ADD COLUMN     "externalId" TEXT;

-- CreateTable
CREATE TABLE "hotel_integrations" (
    "hotelId" TEXT NOT NULL,
    "apiKeyHash" TEXT NOT NULL,
    "apiKeyPrefix" TEXT NOT NULL,
    "webhookUrl" TEXT,
    "webhookSecret" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "lastInboundSyncAt" TIMESTAMP(3),
    "lastOutboundAt" TIMESTAMP(3),
    "lastOutboundOk" BOOLEAN,
    "lastOutboundError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hotel_integrations_pkey" PRIMARY KEY ("hotelId")
);

-- CreateIndex
CREATE UNIQUE INDEX "hotel_integrations_apiKeyHash_key" ON "hotel_integrations"("apiKeyHash");

-- CreateIndex
CREATE UNIQUE INDEX "stays_hotelId_externalId_key" ON "stays"("hotelId", "externalId");

-- CreateIndex
CREATE UNIQUE INDEX "guests_hotelId_externalId_key" ON "guests"("hotelId", "externalId");

-- CreateIndex
CREATE UNIQUE INDEX "services_hotelId_externalId_key" ON "services"("hotelId", "externalId");

-- CreateIndex
CREATE UNIQUE INDEX "service_items_serviceId_externalId_key" ON "service_items"("serviceId", "externalId");

-- AddForeignKey
ALTER TABLE "hotel_integrations" ADD CONSTRAINT "hotel_integrations_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
