-- CreateEnum
CREATE TYPE "MessageSender" AS ENUM ('guest', 'staff');

-- CreateTable
CREATE TABLE "stay_messages" (
    "id" TEXT NOT NULL,
    "stayId" TEXT NOT NULL,
    "senderType" "MessageSender" NOT NULL,
    "guestId" TEXT,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "readByStaff" BOOLEAN NOT NULL DEFAULT false,
    "readByGuest" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "stay_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stay_messages_stayId_idx" ON "stay_messages"("stayId");

-- CreateIndex
CREATE INDEX "stay_messages_guestId_idx" ON "stay_messages"("guestId");

-- AddForeignKey
ALTER TABLE "stay_messages" ADD CONSTRAINT "stay_messages_stayId_fkey" FOREIGN KEY ("stayId") REFERENCES "stays"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stay_messages" ADD CONSTRAINT "stay_messages_guestId_fkey" FOREIGN KEY ("guestId") REFERENCES "guests"("id") ON DELETE SET NULL ON UPDATE CASCADE;
