-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('active', 'trial', 'suspended', 'cancelled');

-- CreateEnum
CREATE TYPE "SubscriptionPaymentStatus" AS ENUM ('em_dia', 'atrasado', 'isento');

-- CreateEnum
CREATE TYPE "SupportMessageSender" AS ENUM ('hotel', 'platform');

-- CreateTable
CREATE TABLE "platform_admins" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "platform_admins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "hotel_subscriptions" (
    "hotelId" TEXT NOT NULL,
    "planName" TEXT NOT NULL,
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'trial',
    "paymentStatus" "SubscriptionPaymentStatus" NOT NULL DEFAULT 'em_dia',
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hotel_subscriptions_pkey" PRIMARY KEY ("hotelId")
);

-- CreateTable
CREATE TABLE "platform_support_messages" (
    "id" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "senderType" "SupportMessageSender" NOT NULL,
    "staffId" TEXT,
    "body" TEXT NOT NULL,
    "readByPlatform" BOOLEAN NOT NULL DEFAULT false,
    "readByHotel" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "platform_support_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "platform_admins_email_key" ON "platform_admins"("email");

-- CreateIndex
CREATE INDEX "platform_support_messages_hotelId_idx" ON "platform_support_messages"("hotelId");

-- AddForeignKey
ALTER TABLE "hotel_subscriptions" ADD CONSTRAINT "hotel_subscriptions_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "platform_support_messages" ADD CONSTRAINT "platform_support_messages_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
