-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "tableTypeId" TEXT;

-- AlterTable
ALTER TABLE "services" ADD COLUMN     "operatingDaysOfWeek" INTEGER[] DEFAULT ARRAY[]::INTEGER[],
ADD COLUMN     "operatingEndMinute" INTEGER,
ADD COLUMN     "operatingStartMinute" INTEGER;

-- CreateTable
CREATE TABLE "restaurant_table_types" (
    "id" TEXT NOT NULL,
    "serviceId" TEXT NOT NULL,
    "label" TEXT,
    "seats" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,

    CONSTRAINT "restaurant_table_types_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "restaurant_table_types_serviceId_idx" ON "restaurant_table_types"("serviceId");

-- CreateIndex
CREATE INDEX "orders_tableTypeId_scheduledFor_idx" ON "orders"("tableTypeId", "scheduledFor");

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_tableTypeId_fkey" FOREIGN KEY ("tableTypeId") REFERENCES "restaurant_table_types"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "restaurant_table_types" ADD CONSTRAINT "restaurant_table_types_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "services"("id") ON DELETE CASCADE ON UPDATE CASCADE;
