import { useState, useCallback, useEffect } from "react";
import type { Driver, DriverStatus } from "@/api/types";
import { mockDrivers } from "@/mocks/drivers";

const USE_MOCK = import.meta.env.VITE_USE_MOCK === "true";

export function useDrivers() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDrivers = useCallback(async (status?: DriverStatus) => {
    setIsLoading(true);
    setError(null);

    try {
      if (USE_MOCK) {
        await new Promise((r) => setTimeout(r, 500));
        const filtered = status
          ? mockDrivers.filter((d) => d.status === status)
          : mockDrivers;
        setDrivers(filtered);
      } else {
        const { default: apiClient } = await import("@/api/client");
        const { API_ENDPOINTS } = await import("@/api/endpoints");
        const url = status === "pending" ? API_ENDPOINTS.DRIVERS_PENDING : API_ENDPOINTS.DRIVERS;
        const res = await apiClient.get(url, { params: status && status !== "pending" ? { status } : undefined });
        setDrivers(res.data.data || res.data);
      }
    } catch (err) {
      setError("Gagal memuat data driver");
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const fetchDriverDetail = useCallback(async (id: string): Promise<Driver | null> => {
    try {
      if (USE_MOCK) {
        await new Promise((r) => setTimeout(r, 300));
        return mockDrivers.find((d) => d.id === id) || null;
      }
      const { default: apiClient } = await import("@/api/client");
      const { API_ENDPOINTS } = await import("@/api/endpoints");
      const res = await apiClient.get(API_ENDPOINTS.DRIVER_DETAIL(id));
      return res.data;
    } catch {
      return null;
    }
  }, []);

  const approveDriver = useCallback(async (id: string): Promise<boolean> => {
    try {
      if (USE_MOCK) {
        await new Promise((r) => setTimeout(r, 600));
        setDrivers((prev) =>
          prev.map((d) =>
            d.id === id
              ? { ...d, status: "approved" as const, approvedAt: new Date().toISOString() }
              : d
          )
        );
        return true;
      }
      const { default: apiClient } = await import("@/api/client");
      const { API_ENDPOINTS } = await import("@/api/endpoints");
      await apiClient.post(API_ENDPOINTS.DRIVER_APPROVE(id));
      return true;
    } catch {
      return false;
    }
  }, []);

  const rejectDriver = useCallback(async (id: string, reason: string): Promise<boolean> => {
    try {
      if (USE_MOCK) {
        await new Promise((r) => setTimeout(r, 600));
        setDrivers((prev) =>
          prev.map((d) =>
            d.id === id
              ? { ...d, status: "rejected" as const, rejectedAt: new Date().toISOString(), rejectionReason: reason }
              : d
          )
        );
        return true;
      }
      const { default: apiClient } = await import("@/api/client");
      const { API_ENDPOINTS } = await import("@/api/endpoints");
      await apiClient.post(API_ENDPOINTS.DRIVER_REJECT(id), { reason });
      return true;
    } catch {
      return false;
    }
  }, []);

  return {
    drivers,
    isLoading,
    error,
    fetchDrivers,
    fetchDriverDetail,
    approveDriver,
    rejectDriver,
  };
}

export function useDriverDetail(id: string) {
  const [driver, setDriver] = useState<Driver | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setIsLoading(true);
      try {
        if (USE_MOCK) {
          await new Promise((r) => setTimeout(r, 300));
          setDriver(mockDrivers.find((d) => d.id === id) || null);
        } else {
          const { default: apiClient } = await import("@/api/client");
          const { API_ENDPOINTS } = await import("@/api/endpoints");
          const res = await apiClient.get(API_ENDPOINTS.DRIVER_DETAIL(id));
          setDriver(res.data);
        }
      } catch {
        setDriver(null);
      } finally {
        setIsLoading(false);
      }
    };
    load();
  }, [id]);

  return { driver, setDriver, isLoading };
}
