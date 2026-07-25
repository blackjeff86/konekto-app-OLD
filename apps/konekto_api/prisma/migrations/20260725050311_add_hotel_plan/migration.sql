-- CreateEnum
CREATE TYPE "HotelPlan" AS ENUM ('essential', 'premium', 'enterprise');

-- AlterTable
ALTER TABLE "hotel_subscriptions" ADD COLUMN     "plan" "HotelPlan" NOT NULL DEFAULT 'essential';
