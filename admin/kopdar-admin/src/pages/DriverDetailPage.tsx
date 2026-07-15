import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import toast from "react-hot-toast";
import PageHeader from "@/components/layout/PageHeader";
import StatusBadge from "@/components/common/StatusBadge";
import LoadingSpinner from "@/components/common/LoadingSpinner";
import ConfirmDialog from "@/components/common/ConfirmDialog";
import { useDriverDetail, useDrivers } from "@/hooks/useDrivers";

export default function DriverDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { driver, setDriver, isLoading } = useDriverDetail(id || "");
  const { approveDriver, rejectDriver } = useDrivers();

  const [showApprove, setShowApprove] = useState(false);
  const [showReject, setShowReject] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  if (isLoading) return <LoadingSpinner className="py-20" />;
  if (!driver) {
    return (
      <div className="py-20 text-center">
        <p className="text-gray-500">Driver tidak ditemukan.</p>
        <button onClick={() => navigate(-1)} className="btn btn-outline mt-4">
          Kembali
        </button>
      </div>
    );
  }

  const handleApprove = async () => {
    setActionLoading(true);
    const success = await approveDriver(driver.id);
    setActionLoading(false);
    setShowApprove(false);

    if (success) {
      setDriver({ ...driver, status: "approved", approvedAt: new Date().toISOString() });
      toast.success(`${driver.name} telah disetujui!`);
    } else {
      toast.error("Gagal menyetujui driver");
    }
  };

  const handleReject = async () => {
    if (!rejectReason.trim()) {
      toast.error("Masukkan alasan penolakan");
      return;
    }
    setActionLoading(true);
    const success = await rejectDriver(driver.id, rejectReason);
    setActionLoading(false);
    setShowReject(false);

    if (success) {
      setDriver({
        ...driver,
        status: "rejected",
        rejectedAt: new Date().toISOString(),
        rejectionReason: rejectReason,
      });
      setRejectReason("");
      toast.success(`${driver.name} telah ditolak`);
    } else {
      toast.error("Gagal menolak driver");
    }
  };

  const InfoRow = ({ label, value }: { label: string; value: string | undefined | null }) => (
    <div className="py-2">
      <dt className="text-xs font-medium uppercase tracking-wider text-gray-400">{label}</dt>
      <dd className="mt-0.5 text-sm text-gray-900">{value || "-"}</dd>
    </div>
  );

  return (
    <div>
      <PageHeader
        title="Detail Driver"
        subtitle={driver.name}
        action={
          <button onClick={() => navigate(-1)} className="btn btn-outline">
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Kembali
          </button>
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left: Info */}
        <div className="space-y-6 lg:col-span-2">
          {/* Status Card */}
          <div className="card p-5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 text-lg font-bold text-primary">
                  {driver.name.charAt(0)}
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">{driver.name}</h3>
                  <p className="text-sm text-gray-500">{driver.phone}</p>
                </div>
              </div>
              <StatusBadge status={driver.status} />
            </div>
            {driver.status === "rejected" && driver.rejectionReason && (
              <div className="mt-4 rounded-lg bg-red-50 p-3">
                <p className="text-xs font-medium text-red-700">Alasan Penolakan:</p>
                <p className="mt-1 text-sm text-red-600">{driver.rejectionReason}</p>
              </div>
            )}
          </div>

          {/* Personal Info */}
          <div className="card p-5">
            <h4 className="mb-4 font-semibold text-gray-900">Informasi Pribadi</h4>
            <dl className="grid grid-cols-2 gap-x-6 gap-y-1">
              <InfoRow label="NIK" value={driver.nik} />
              <InfoRow label="Email" value={driver.email} />
              <InfoRow label="Jenis Kelamin" value={driver.gender === "L" ? "Laki-laki" : "Perempuan"} />
              <InfoRow label="Tanggal Lahir" value={driver.dateOfBirth} />
              <div className="col-span-2">
                <InfoRow label="Alamat" value={`${driver.address}, ${driver.city}, ${driver.province} ${driver.postalCode}`} />
              </div>
            </dl>
          </div>

          {/* Vehicle Info */}
          <div className="card p-5">
            <h4 className="mb-4 font-semibold text-gray-900">Informasi Kendaraan</h4>
            <dl className="grid grid-cols-2 gap-x-6 gap-y-1">
              <InfoRow label="Tipe" value={driver.vehicleType === "motor" ? "Motor" : "Mobil"} />
              <InfoRow label="Plat Nomor" value={driver.vehiclePlate} />
              <InfoRow label="Merk" value={driver.vehicleBrand} />
              <InfoRow label="Model" value={driver.vehicleModel} />
              <InfoRow label="Tahun" value={String(driver.vehicleYear)} />
              <InfoRow label="Warna" value={driver.vehicleColor} />
            </dl>
          </div>

          {/* Platforms */}
          <div className="card p-5">
            <h4 className="mb-3 font-semibold text-gray-900">Platform</h4>
            <div className="flex flex-wrap gap-2">
              {driver.platforms.map((p) => (
                <span key={p} className="rounded-lg bg-primary/10 px-3 py-1.5 text-sm font-medium text-primary capitalize">
                  {p}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Right: Photos + Actions */}
        <div className="space-y-6">
          {/* Photos */}
          <div className="card p-5">
            <h4 className="mb-4 font-semibold text-gray-900">Foto</h4>
            <div className="space-y-4">
              {[
                { label: "Foto KTP", src: driver.photoKtp },
                { label: "Foto Selfie", src: driver.photoSelfie },
                { label: "Foto Kendaraan", src: driver.photoVehicle },
                ...(driver.photoSim ? [{ label: "Foto SIM", src: driver.photoSim }] : []),
              ].map((photo) => (
                <div key={photo.label}>
                  <p className="mb-2 text-xs font-medium text-gray-500">{photo.label}</p>
                  <img
                    src={photo.src}
                    alt={photo.label}
                    className="w-full rounded-lg border border-gray-200 object-cover"
                  />
                </div>
              ))}
            </div>
          </div>

          {/* Action Buttons */}
          {driver.status === "pending" && (
            <div className="card p-5">
              <h4 className="mb-4 font-semibold text-gray-900">Aksi</h4>
              <div className="space-y-3">
                <button onClick={() => setShowApprove(true)} className="btn btn-primary w-full">
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  Setujui Driver
                </button>
                <button onClick={() => setShowReject(true)} className="btn btn-danger w-full">
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  Tolak Driver
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Approve Dialog */}
      <ConfirmDialog
        open={showApprove}
        title="Setujui Driver?"
        message={`Apakah Anda yakin ingin menyetujui pendaftaran ${driver.name}? Driver akan mulai bisa menerima pesanan.`}
        confirmLabel="Ya, Setujui"
        loading={actionLoading}
        onConfirm={handleApprove}
        onCancel={() => setShowApprove(false)}
      />

      {/* Reject Dialog */}
      <ConfirmDialog
        open={showReject}
        title="Tolak Driver?"
        message={`Masukkan alasan penolakan untuk ${driver.name}:`}
        confirmLabel="Tolak"
        danger
        loading={actionLoading}
        onConfirm={handleReject}
        onCancel={() => {
          setShowReject(false);
          setRejectReason("");
        }}
      />

      {/* Reject Reason Input (overlay on top of confirm dialog) */}
      {showReject && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/50" onClick={() => setShowReject(false)} />
          <div className="relative w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h3 className="text-lg font-semibold text-gray-900">Tolak Driver</h3>
            <p className="mt-1 text-sm text-gray-500">Masukkan alasan penolakan untuk {driver.name}</p>

            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Contoh: Foto KTP tidak jelas, NIK tidak terbaca..."
              rows={4}
              className="input mt-4 resize-none"
            />

            <div className="mt-4 flex justify-end gap-3">
              <button
                onClick={() => {
                  setShowReject(false);
                  setRejectReason("");
                }}
                disabled={actionLoading}
                className="btn btn-outline"
              >
                Batal
              </button>
              <button onClick={handleReject} disabled={actionLoading} className="btn btn-danger">
                {actionLoading ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                    Memproses...
                  </span>
                ) : (
                  "Tolak Driver"
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
