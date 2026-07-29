-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "recordedByStaffId" TEXT,
ADD COLUMN     "statusSeenByGuest" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "service_items" ADD COLUMN     "isMinibarItem" BOOLEAN NOT NULL DEFAULT false;
