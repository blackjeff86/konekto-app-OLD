-- CreateEnum
CREATE TYPE "PaymentAccountStatus" AS ENUM ('pending', 'verified', 'rejected');

-- CreateEnum
CREATE TYPE "StayPaymentStatus" AS ENUM ('pending', 'paid', 'failed');

-- CreateTable
CREATE TABLE "hotel_payment_accounts" (
    "hotelId" TEXT NOT NULL,
    "pagarmeRecipientId" TEXT NOT NULL,
    "status" "PaymentAccountStatus" NOT NULL DEFAULT 'pending',
    "pagarmeStatus" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hotel_payment_accounts_pkey" PRIMARY KEY ("hotelId")
);

-- CreateTable
CREATE TABLE "stay_payments" (
    "id" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "stayId" TEXT NOT NULL,
    "guestId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "platformFeeAmount" DOUBLE PRECISION NOT NULL,
    "hotelAmount" DOUBLE PRECISION NOT NULL,
    "pagarmeOrderId" TEXT,
    "pagarmeChargeId" TEXT,
    "status" "StayPaymentStatus" NOT NULL DEFAULT 'pending',
    "failureReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stay_payments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stay_payments_stayId_idx" ON "stay_payments"("stayId");

-- CreateIndex
CREATE INDEX "stay_payments_hotelId_idx" ON "stay_payments"("hotelId");

-- AddForeignKey
ALTER TABLE "hotel_payment_accounts" ADD CONSTRAINT "hotel_payment_accounts_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stay_payments" ADD CONSTRAINT "stay_payments_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stay_payments" ADD CONSTRAINT "stay_payments_stayId_fkey" FOREIGN KEY ("stayId") REFERENCES "stays"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stay_payments" ADD CONSTRAINT "stay_payments_guestId_fkey" FOREIGN KEY ("guestId") REFERENCES "guests"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
