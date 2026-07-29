CREATE TYPE "GuestNotificationChannel" AS ENUM ('in_app', 'browser', 'email', 'whatsapp');

CREATE TYPE "GuestNotificationStatus" AS ENUM ('unread', 'read');

CREATE TABLE "guest_notifications" (
    "id" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "guestId" TEXT NOT NULL,
    "moduleId" TEXT NOT NULL,
    "channel" "GuestNotificationChannel" NOT NULL DEFAULT 'in_app',
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "relatedEntityType" TEXT,
    "relatedEntityId" TEXT,
    "dedupeKey" TEXT,
    "status" "GuestNotificationStatus" NOT NULL DEFAULT 'unread',
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "guest_notifications_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "guest_notifications_guestId_dedupeKey_key" ON "guest_notifications"("guestId", "dedupeKey");
CREATE INDEX "guest_notifications_hotelId_idx" ON "guest_notifications"("hotelId");
CREATE INDEX "guest_notifications_guestId_status_idx" ON "guest_notifications"("guestId", "status");

ALTER TABLE "guest_notifications" ADD CONSTRAINT "guest_notifications_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "guest_notifications" ADD CONSTRAINT "guest_notifications_guestId_fkey" FOREIGN KEY ("guestId") REFERENCES "guests"("id") ON DELETE CASCADE ON UPDATE CASCADE;
