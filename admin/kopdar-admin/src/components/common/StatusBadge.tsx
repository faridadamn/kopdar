import clsx from "clsx";
import type { DriverStatus } from "@/api/types";

interface StatusBadgeProps {
  status: DriverStatus;
  className?: string;
}

const statusConfig: Record<DriverStatus, { label: string; classes: string }> = {
  pending: {
    label: "Menunggu",
    classes: "bg-yellow-100 text-yellow-800 ring-yellow-600/20",
  },
  approved: {
    label: "Disetujui",
    classes: "bg-green-100 text-green-800 ring-green-600/20",
  },
  rejected: {
    label: "Ditolak",
    classes: "bg-red-100 text-red-800 ring-red-600/20",
  },
};

export default function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = statusConfig[status];

  return (
    <span
      className={clsx(
        "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset",
        config.classes,
        className
      )}
    >
      {config.label}
    </span>
  );
}
