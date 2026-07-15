import type { DashboardStats } from "@/api/types";

export const mockDashboardStats: DashboardStats = {
  totalDrivers: 20,
  pendingVerifications: 8,
  approvedDrivers: 10,
  rejectedDrivers: 2,
  newDriversThisMonth: 5,
  activeDriversToday: 12,
  topPlatform: "grab",
  approvalRate: 83.3,
};
