export const API_ENDPOINTS = {
  // Auth
  AUTH_LOGIN: "/auth/login",
  AUTH_SEND_OTP: "/auth/send-otp",
  AUTH_VERIFY_OTP: "/auth/verify-otp",
  AUTH_ME: "/auth/me",

  // Drivers
  DRIVERS: "/drivers",
  DRIVERS_PENDING: "/drivers/pending",
  DRIVER_DETAIL: (id: string) => `/drivers/${id}`,
  DRIVER_APPROVE: (id: string) => `/drivers/${id}/approve`,
  DRIVER_REJECT: (id: string) => `/drivers/${id}/reject`,

  // Dashboard
  DASHBOARD_STATS: "/dashboard/stats",
  DASHBOARD_RECENT: "/dashboard/recent-activity",

  // Verification
  VERIFICATION_LIST: "/verification",
  VERIFICATION_DETAIL: (id: string) => `/verification/${id}`,
} as const;
