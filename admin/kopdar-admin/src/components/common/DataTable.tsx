import clsx from "clsx";
import LoadingSpinner from "./LoadingSpinner";
import EmptyState from "./EmptyState";
import Pagination from "./Pagination";

export interface Column<T> {
  key: string;
  header: string;
  render: (item: T) => React.ReactNode;
  className?: string;
  headerClassName?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  loading?: boolean;
  emptyTitle?: string;
  emptyDescription?: string;
  emptyIcon?: React.ReactNode;
  currentPage?: number;
  totalPages?: number;
  onPageChange?: (page: number) => void;
  onRowClick?: (item: T) => void;
  keyExtractor: (item: T) => string;
  className?: string;
}

export default function DataTable<T>({
  columns,
  data,
  loading = false,
  emptyTitle = "Tidak ada data",
  emptyDescription = "Belum ada data yang tersedia.",
  emptyIcon,
  currentPage,
  totalPages,
  onPageChange,
  onRowClick,
  keyExtractor,
  className,
}: DataTableProps<T>) {
  if (loading) {
    return (
      <div className="card">
        <LoadingSpinner className="py-20" />
      </div>
    );
  }

  if (data.length === 0) {
    return (
      <div className="card">
        <EmptyState
          icon={emptyIcon}
          title={emptyTitle}
          description={emptyDescription}
        />
      </div>
    );
  }

  return (
    <div className={clsx("card overflow-hidden", className)}>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={clsx(
                    "px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500",
                    col.headerClassName
                  )}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {data.map((item) => (
              <tr
                key={keyExtractor(item)}
                onClick={() => onRowClick?.(item)}
                className={clsx(
                  "transition-colors",
                  onRowClick && "cursor-pointer hover:bg-gray-50"
                )}
              >
                {columns.map((col) => (
                  <td key={col.key} className={clsx("px-4 py-3.5 text-sm text-gray-700", col.className)}>
                    {col.render(item)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {currentPage !== undefined && totalPages !== undefined && onPageChange && (
        <div className="border-t border-gray-200 px-4 py-3">
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={onPageChange}
          />
        </div>
      )}
    </div>
  );
}
