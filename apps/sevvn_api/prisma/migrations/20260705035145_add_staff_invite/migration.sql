-- CreateTable
CREATE TABLE "staff_invites" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "hotelId" TEXT NOT NULL,
    "role" "StaffRole" NOT NULL DEFAULT 'recepcao',
    "consumed" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "staff_invites_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "staff_invites_code_key" ON "staff_invites"("code");

-- CreateIndex
CREATE INDEX "staff_invites_hotelId_idx" ON "staff_invites"("hotelId");

-- AddForeignKey
ALTER TABLE "staff_invites" ADD CONSTRAINT "staff_invites_hotelId_fkey" FOREIGN KEY ("hotelId") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
