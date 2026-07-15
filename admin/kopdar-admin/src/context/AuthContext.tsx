import { createContext, useState, useCallback, useEffect } from "react";
import type { User } from "@/api/types";

interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (phone: string, otp: string) => Promise<boolean>;
  logout: () => void;
  isAuthenticated: boolean;
  isLoading: boolean;
}

export const AuthContext = createContext<AuthContextType | null>(null);

const MOCK_ADMIN: User = {
  id: "admin-001",
  name: "Admin KopDar",
  phone: "081234567890",
  role: "superadmin",
  avatar: undefined,
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(() => {
    const saved = localStorage.getItem("kopdar_admin_user");
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState<string | null>(() =>
    localStorage.getItem("kopdar_admin_token")
  );
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Validate token on mount
    const validateToken = async () => {
      if (token) {
        try {
          // In mock mode, just trust the stored data
          if (import.meta.env.VITE_USE_MOCK === "true") {
            setIsLoading(false);
            return;
          }
          // Real API validation would go here
        } catch {
          logout();
        }
      }
      setIsLoading(false);
    };
    validateToken();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const login = useCallback(async (phone: string, otp: string): Promise<boolean> => {
    setIsLoading(true);

    // Mock login: any phone + OTP "123456"
    if (import.meta.env.VITE_USE_MOCK === "true") {
      await new Promise((r) => setTimeout(r, 800)); // simulate delay

      if (otp === "123456") {
        const mockToken = "mock-jwt-token-" + Date.now();
        const adminUser: User = { ...MOCK_ADMIN, phone };

        localStorage.setItem("kopdar_admin_token", mockToken);
        localStorage.setItem("kopdar_admin_user", JSON.stringify(adminUser));
        setToken(mockToken);
        setUser(adminUser);
        setIsLoading(false);
        return true;
      }

      setIsLoading(false);
      return false;
    }

    // Real API login
    try {
      const { default: apiClient } = await import("@/api/client");
      const { API_ENDPOINTS } = await import("@/api/endpoints");
      const res = await apiClient.post(API_ENDPOINTS.AUTH_LOGIN, { phone, otp });
      const { token: newToken, user: newUser } = res.data;

      localStorage.setItem("kopdar_admin_token", newToken);
      localStorage.setItem("kopdar_admin_user", JSON.stringify(newUser));
      setToken(newToken);
      setUser(newUser);
      setIsLoading(false);
      return true;
    } catch {
      setIsLoading(false);
      return false;
    }
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem("kopdar_admin_token");
    localStorage.removeItem("kopdar_admin_user");
    setToken(null);
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        login,
        logout,
        isAuthenticated: !!token && !!user,
        isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
