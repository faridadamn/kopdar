export type DriverStatus = "pending" | "approved" | "rejected";

export type DriverPlatform = "grab" | "gojek" | "shopeefood" | "maxim" | "indriver";

export interface User {
  id: string;
  name: string;
  phone: string;
  role: "admin" | "superadmin";
  avatar?: string;
}

export interface Driver {
  id: string;
  name: string;
  phone: string;
  email?: string;
  nik: string;
  address: string;
  city: string;
  province: string;
  postalCode: string;
  dateOfBirth: string;
  gender: "L" | "P";
  status: DriverStatus;
  platforms: DriverPlatform[];
  vehicleType: "motor" | "mobil";
  vehicleBrand: string;
  vehicleModel: string;
  vehicleYear: number;
  vehiclePlate: string;
  vehicleColor: string;
  photoKtp: string;
  photoSelfie: string;
  photoVehicle: string;
  photoSim?: string;
  notes?: string;
  rejectionReason?: string;
  createdAt: string;
  updatedAt: string;
  approvedAt?: string;
  rejectedAt?: string;
}

export interface DashboardStats {
  totalDrivers: number;
  pendingVerifications: number;
  approvedDrivers: number;
  rejectedDrivers: number;
  newDriversThisMonth: number;
  activeDriversToday: number;
  topPlatform: DriverPlatform;
  approvalRate: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  perPage: number;
  totalPages: number;
}

export interface LoginRequest {
  phone: string;
  otp: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface ApiError {
  message: string;
  code: string;
  status: number;
}
