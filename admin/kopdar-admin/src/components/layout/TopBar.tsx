import { useAuth } from "@/hooks/useAuth";
import { useLocation } from "react-router-dom";

interface TopBarProps {
  onMenuClick: () => void;
}

const pageTitles: Record<string, string> = {
  "/": "Dashboard",
  "/verifikasi": "Verifikasi Driver",
  "/drivers": "Semua Driver",
  "/settings": "Pengaturan",
};

export default function TopBar({ onMenuClick }: TopBarProps) {
  const { user, logout } = useAuth();
  const location = useLocation();

  const title =
    location.pathname.startsWith("/drivers/")
      ? "Detail Driver"
      : pageTitles[location.pathname] || "Dashboard";

  return (
    <header className="flex h-16 items-center justify-between border-b border-gray-200 bg-white px-4 md:px-6">
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="rounded-lg p-2 text-gray-500 hover:bg-gray-100 lg:hidden"
        >
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
        <h2 className="text-lg font-semibold text-gray-800">{title}</h2>
      </div>

      <div className="flex items-center gap-3">
        <div className="hidden text-right md:block">
          <p className="text-sm font-medium text-gray-700">{user?.name || "Admin"}</p>
          <p className="text-xs text-gray-400">{user?.role === "superadmin" ? "Super Admin" : "Admin"}</p>
        </div>
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-sm font-bold text-white">
          {user?.name?.charAt(0) || "A"}
        </div>
        <button
          onClick={logout}
          className="rounded-lg p-2 text-gray-400 transition-colors hover:bg-danger/10 hover:text-danger"
          title="Keluar"
        >
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
        </button>
      </div>
    </header>
  );
}
