import type { DataTableColumn } from "@/components/ui/DataTable";

// Card-list companion to DataTable, for narrow (phone-width) viewports —
// same columns/rows/rowKey shape, so a caller renders both from one
// column definition and toggles which is visible via CSS breakpoints
// (see AddressSearchList) rather than maintaining two column lists.
type DataCardListProps<T> = {
  columns: DataTableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  rowId?: (row: T) => string;
  emptyMessage?: string;
};

export default function DataCardList<T>({
  columns,
  rows,
  rowKey,
  rowId,
  emptyMessage = "データがありません。",
}: DataCardListProps<T>) {
  if (rows.length === 0) {
    return <p className="py-8 text-center text-brand-gray-500">{emptyMessage}</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {rows.map((row) => (
        <li
          key={rowKey(row)}
          id={rowId?.(row)}
          className="rounded-lg border border-brand-gray-200 bg-white p-4 shadow-sm"
        >
          <dl className="flex flex-col gap-2">
            {columns.map((column) => (
              <div key={column.key} className="flex flex-col">
                <dt className="text-xs font-medium text-brand-gray-500">{column.header}</dt>
                <dd className="text-sm text-brand-gray-900">{column.render(row)}</dd>
              </div>
            ))}
          </dl>
        </li>
      ))}
    </ul>
  );
}
