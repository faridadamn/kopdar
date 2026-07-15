import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import PageHeader from "@/components/layout/PageHeader";
import DataTable, { type Column } from "@/components/common/DataTable";
import SearchInput from "@/components/common/SearchInput";
import StatusBadge from "@/components/common/StatusBadge";
import { useDrivers } from "@/hooks/useDrivers";
import type { Driver } from "@/api/types";
import { format } from "date-fns";
import { id as idLocale } from "date-fns/locale";

export default function PendingVerificationsPage() {
  const navigate = useNavigate();
  const { drivers, isLoading, fetchDrivers } = useDrivers();
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const perPage = 10;

  useEffect(() => {
    fetchDrivers("pending");
  }, [fetchDrivers]);

  const filtered = useMemo(() => {
    if (!search.trim()) return drivers;
    const q = search.toLowerCase();
    return drivers.filter(
      (d) =>
        d.name.toLowerCase().includes(q) ||
        d.phone.includes(q) ||
        d.nik.includes(q) ||
        d.city.toLowerCase().includes(q)
    );
  }, [drivers, search]);

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
      header: "Lokasi",
      render: (d) => <span>{d.city}</span>,
    },
    {
      key: "vehicle",
      header: "Kendaraan",
      render: (d) => (
        <span>
          {d.vehicleBrand} {d.vehicleModel} ({d.vehicleYear})
        </span>
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
      header: "Tanggal Daftar",
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
        title="Verifikasi Driver"
        subtitle={`${drivers.length} driver menunggu verifikasi`}
        action={
          <SearchInput
            value={search}
            onChange={(v) => {
              setSearch(v);
              setPage(1);
            }}
            placeholder="Cari nama, NIK, atau kota..."
            className="w-64"
          />
        }
      />

      <DataTable
        columns={columns}
        data={paginated}
        loading={isLoading}
        emptyTitle="Tidak ada verifikasi"
        emptyDescription="Semua pendaftaran driver sudah diproses."
        emptyIcon={
          <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
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
