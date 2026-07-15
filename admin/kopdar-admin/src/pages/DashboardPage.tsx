import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import PageHeader from "@/components/layout/PageHeader";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import type { DashboardStats } from "@/api/types";
import { mockDashboardStats } from "@/mocks/stats";
import { useAuth } from "@/hooks/useAuth";

const USE_MOCK = import.meta.env.VITE_USE_MOCK === "true";

export default function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      if (USE_MOCK) {
        await new Promise((r) => setTimeout(r, 400));
        setStats(mockDashboardStats);
      } else {
        try {
          const { default: apiClient } = await import("@/api/client");
          const { API_ENDPOINTS } = await import("@/api/endpoints");
          const res = await apiClient.get(API_ENDPOINTS.DASHBOARD_STATS);
          setStats(res.data);
        } catch {
          setStats(mockDashboardStats);
        }
      }
      setLoading(false);
    };
    load();
  }, []);

  if (loading) return <LoadingSpinner className="py-20" />;

  const statCards = stats
    ? [
        {
          label: "Total Driver",
          value: stats.totalDrivers,
          icon: (
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          ),
          color: "bg-primary/10 text-primary",
          change: `+${stats.newDriversThisMonth} bulan ini`,
        },
        {
          label: "Menunggu Verifikasi",
          value: stats.pendingVerifications,
          icon: (
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          ),
          color: "bg-yellow-100 text-yellow-700",
          action: () => navigate("/verifikasi"),
        },
        {
          label: "Driver Aktif",
          value: stats.approvedDrivers,
          icon: (
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          ),
          color: "bg-green-100 text-green-700",
          change: `${stats.approvalRate}% tingkat persetujuan`,
        },
        {
          label: "Ditolak",
          value: stats.rejectedDrivers,
          icon: (
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          ),
          color: "bg-red-100 text-red-700",
        },
      ]
    : [];

  return (
    <div>
      <PageHeader
        title={`Selamat datang, ${user?.name?.split(" ")[0] || "Admin"} 👋`}
        subtitle="Berikut ringkasan aktivitas KopDar hari ini."
      />

      {/* Stat Cards */}
      <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((card) => (
          <div
            key={card.label}
            onClick={card.action}
            className={`card p-5 ${card.action ? "cursor-pointer transition-shadow hover:shadow-md" : ""}`}
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500">{card.label}</p>
                <p className="mt-1 text-3xl font-bold text-gray-900">{card.value}</p>
                {card.change && (
                  <p className="mt-1 text-xs text-gray-400">{card.change}</p>
                )}
              </div>
              <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${card.color}`}>
                {card.icon}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activity Placeholder */}
      <div className="card p-6">
        <h3 className="mb-4 text-lg font-semibold text-gray-900">Aktivitas Terbaru</h3>
        <div className="space-y-4">
          {[
            { text: "Budi Santoso mendaftar sebagai driver", time: "2 jam yang lalu", type: "new" },
            { text: "Joko Widodo Putra disetujui", time: "5 jam yang lalu", type: "approved" },
            { text: "Tono Sugiarto ditolak", time: "1 hari yang lalu", type: "rejected" },
            { text: "Rina Wati disetujui", time: "2 hari yang lalu", type: "approved" },
            { text: "Ahmad Hidayat mendaftar sebagai driver", time: "3 hari yang lalu", type: "new" },
          ].map((activity, i) => (
            <div key={i} className="flex items-center gap-3">
              <div
                className={`flex h-8 w-8 items-center justify-center rounded-full ${
                  activity.type === "new"
                    ? "bg-blue-100 text-blue-600"
                    : activity.type === "approved"
                      ? "bg-green-100 text-green-600"
                      : "bg-red-100 text-red-600"
                }`}
              >
                {activity.type === "new" ? (
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                  </svg>
                ) : activity.type === "approved" ? (
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                )}
              </div>
              <div className="flex-1">
                <p className="text-sm text-gray-700">{activity.text}</p>
              </div>
              <span className="text-xs text-gray-400">{activity.time}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
