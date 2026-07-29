-- AlterTable
ALTER TABLE "service_items" ADD COLUMN     "availabilityEndMinute" INTEGER,
ADD COLUMN     "availabilityStartMinute" INTEGER,
ADD COLUMN     "availableDaysOfWeek" INTEGER[] DEFAULT ARRAY[]::INTEGER[],
ADD COLUMN     "capacityPerSlot" INTEGER,
ADD COLUMN     "durationMinutes" INTEGER;

-- CreateIndex
CREATE INDEX "orders_serviceItemId_scheduledFor_idx" ON "orders"("serviceItemId", "scheduledFor");
