export type GuestTemplateId =
  | "aura"
  | "bosque"
  | "elite"
  | "pulse"
  | "horizon";

export type HotelPlan = "essential" | "premium" | "enterprise";

export interface ResolvedHotelModule {
  id: string;
  enabled: boolean;
  configuration: Record<string, unknown>;
}

export interface HotelInfo {
  name?: string;
  logoUrl?: string;
  address?: string;
  promoImages?: {
    images?: string[];
    carouselHeight?: number;
    carouselEnabled?: boolean;
  };
}

export interface ColorPalette {
  primary?: string;
  secondary?: string;
}

export interface GuestHotelConfig {
  id: string;
  hotelInfo?: HotelInfo;
  colorPalette?: ColorPalette;
  template?: GuestTemplateId;
  enabledModules?: ResolvedHotelModule[];
}

export type RestaurantBookingMode =
  | "party_size_only"
  | "table_type_selection"
  | "hybrid";

export interface RestaurantModuleConfig {
  bookingMode?: RestaurantBookingMode;
  showMenuInGuestApp?: boolean;
  showMenuPrices?: boolean;
  maxPartySize?: number;
  tableInventorySource?: "sevvn" | "external" | "hybrid";
  waitlistEnabled?: boolean;
  waitlistCapacity?: number;
  reservationExpiryMinutes?: number;
}

export interface RoomServiceModuleConfig {
  showMinibarInGuestApp?: boolean;
  allowGuestConsumptionReports?: boolean;
  allowStaffConsumptionLaunch?: boolean;
  fulfillmentMode?: "sevvn" | "external" | "hybrid";
}

export interface ConciergeModuleConfig {
  title?: string;
  openingHours?: string;
  requestCategories?: string[];
  responseSlaMinutes?: number;
  showEstimatedResponseTime?: boolean;
  allowFileAttachments?: boolean;
  escalationMode?: "manual" | "automatic" | "hybrid";
}

export interface GuestClaimGuest {
  firstName: string;
  lastName: string;
  roomNumber: string;
  hotelId: string;
  checkInDate: string;
  checkOutDate: string;
  wifiNetworkName: string | null;
  wifiPassword: string | null;
}

export interface GuestClaimResponse {
  token: string;
  guest: GuestClaimGuest;
}

export type ServiceType = "room_service" | "restaurant" | "activity";

export interface FieldTranslations {
  en?: Record<string, string>;
  es?: Record<string, string>;
}

export interface ServiceItem {
  id: string;
  name: string;
  description: string;
  price: number | null;
  imageUrl: string | null;
  location?: string | null;
  category?: string | null;
  extraInfo?: string | null;
  translations?: FieldTranslations | null;
  durationMinutes?: number | null;
  isMinibarItem?: boolean;
}

export interface ServiceTableType {
  id: string;
  name: string;
  capacity: number;
  description?: string | null;
}

export interface GuestTableAvailabilityItem {
  id: string;
  label: string | null;
  seats: number;
  totalQuantity: number;
  availableQuantity: number;
}

export interface GuestTableAvailabilityResponse {
  ok: boolean;
  error?: string;
  tableTypes: GuestTableAvailabilityItem[];
}

export interface GuestScheduledSlot {
  time: string;
  available: boolean;
}

export interface GuestItemAvailabilityResponse {
  schedulingEnabled: boolean;
  durationMinutes?: number;
  slots?: GuestScheduledSlot[];
}

export interface GuestService {
  id: string;
  name: string;
  slug: string;
  icon: string;
  description: string;
  type: ServiceType;
  category?: string | null;
  moduleId?: string | null;
  bannerImageUrl?: string | null;
  translations?: FieldTranslations | null;
  items?: ServiceItem[];
  tableTypes?: ServiceTableType[];
  operatingDaysOfWeek?: number[];
  operatingStartMinute?: number | null;
  operatingEndMinute?: number | null;
}

export type GuestOrderStatus =
  | "pending"
  | "in_progress"
  | "completed"
  | "cancelled";

export interface GuestOrder {
  id: string;
  hotelId: string;
  guestId: string;
  serviceId: string;
  serviceItemId?: string | null;
  itemName: string;
  price?: number | null;
  quantity: number;
  note?: string | null;
  status: GuestOrderStatus;
  scheduledFor?: string | null;
  createdAt: string;
  coupon?: {
    title: string;
  } | null;
}

export interface GuestMessage {
  id: string;
  stayId: string;
  guestId?: string | null;
  senderType: "guest" | "staff";
  body: string;
  readByGuest: boolean;
  readByStaff: boolean;
  createdAt: string;
  guest?: {
    firstName?: string | null;
    lastName?: string | null;
  } | null;
}
