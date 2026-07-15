import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import PageHeader from "@/components/layout/PageHeader";
import DataTable, { type Column } from "@/components/common/DataTable";
import SearchInput from "@/components/common/SearchInput";
import StatusBadge from "@/components/common/StatusBadge";
import { useDrivers } from "@/hooks/useDrivers";
import type { Driver, DriverStatus } from "@/api/types";
import { format } from "date-fns";
import { id as idLocale } from "date-fns/locale";

const statusFilters: { value: DriverStatus | "all"; label: string }[] = [
  { value: "all", label: "Semua" },
  { value: "pending", label: "Menunggu" },
  { value: "approved", label: "Disetujui" },
  { value: "rejected", label: "Ditolak" },
];

export default function AllDriversPage() {
  const navigate = useNavigate();
  const { drivers, isLoading, fetchDrivers } = useDrivers();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<DriverStatus | "all">("all");
  const [page, setPage] = useState(1);
  const perPage = 10;

  useEffect(() => {
    fetchDrivers();
  }, [fetchDrivers]);

  const filtered = useMemo(() => {
    let result = drivers;

    if (statusFilter !== "all") {
      result = result.filter((d) => d.status === statusFilter);
    }

    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter(
        (d) =>
          d.name.toLowerCase().includes(q) ||
          d.phone.includes(q) ||
          d.nik.includes(q) ||
          d.city.toLowerCase().includes(q) ||
          d.vehiclePlate.toLowerCase().includes(q)
      );
    }

    return result;
  }, [drivers, statusFilter, search]);

  const totalPages = Math.ceil(filtered.length / perPage);
  const paginated = filtered.slice((page - 1) * perPage, page * perPage);

  const columns: Column<Driver>[] = [
    {
      key: "name",
      header: "Nama",
      render: (d) => (
        <div>
          <p className="font-medium text-gray-900">{d.name}</p>
          <p className="text-xs text-gray-400">{d.phone}</p>
        </div>
      ),
    },
    {
      key: "nik",
      header: "NIK",
      render: (d) => <span className="font-mono text-xs">{d.nik}</span>,
    },
    {
      key: "location",
      header: "Kota",
      render: (d) => <span>{d.city}</span>,
    },
    {
      key: "vehicle",
      header: "Kendaraan",
      render: (d) => (
        <div>
          <p className="text-sm">
            {d.vehicleBrand} {d.vehicleModel}
          </p>
          <p className="text-xs text-gray-400">{d.vehiclePlate}</p>
        </div>
      ),
    },
    {
      key: "platforms",
      header: "Platform",
      render: (d) => (
        <div className="flex flex-wrap gap-1">
          {d.platforms.map((p) => (
            <span
              key={p}
              className="rounded bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 capitalize"
            >
              {p}
            </span>
          ))}
        </div>
      ),
    },
    {
      key: "status",
      header: "Status",
      render: (d) => <StatusBadge status={d.status} />,
    },
    {
      key: "date",
      header: "Tanggal",
      render: (d) => (
        <span className="text-xs text-gray-500">
          {format(new Date(d.createdAt), "d MMM yyyy", { locale: idLocale })}
        </span>
      ),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Semua Driver"
        subtitle={`Total ${drivers.length} driver terdaftar`}
        action={
          <div className="flex items-center gap-3">
            <SearchInput
              value={search}
              onChange={(v) => {
                setSearch(v);
                setPage(1);
              }}
              placeholder="Cari nama, NIK, plat..."
              className="w-56"
            />
          </div>
        }
      />

      {/* Status Filter Tabs */}
      <div className="mb-4 flex flex-wrap gap-2">
        {statusFilters.map((filter) => {
          const count =
            filter.value === "all"
              ? drivers.length
              : drivers.filter((d) => d.status === filter.value).length;

          return (
            <button
              key={filter.value}
              onClick={() => {
                setStatusFilter(filter.value);
                setPage(1);
              }}
              className={`rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
                statusFilter === filter.value
                  ? "bg-primary text-white"
                  : "bg-white text-gray-600 hover:bg-gray-100"
              }`}
            >
              {filter.label}
              <span
                className={`ml-2 rounded-full px-2 py-0.5 text-xs ${
                  statusFilter === filter.value
                    ? "bg-white/20 text-white"
                    : "bg-gray-200 text-gray-500"
                }`}
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      <DataTable
        columns={columns}
        data={paginated}
        loading={isLoading}
        emptyTitle="Tidak ada driver"
        emptyDescription="Belum ada driver yang terdaftar."
        emptyIcon={
          <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        }
        currentPage={page}
        totalPages={totalPages}
        onPageChange={setPage}
        onRowClick={(d) => navigate(`/drivers/${d.id}`)}
        keyExtractor={(d) => d.id}
      />
    </div>
  );
}
