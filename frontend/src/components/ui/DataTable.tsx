import type { ReactNode } from "react";

// Desktop-first list rendering (spec section 11: PC width uses a table).
// Consumers (Issue #4 employee list, Issue #5/#33 address book list) pass
// typed columns + rows; this component only knows how to lay them out,
// not what the data means. DataCardList reuses the same columns/rows
// shape for the narrow-viewport card layout (see AddressSearchList).
export type DataTableColumn<T> = {
  key: string;
  header: string;
  render: (row: T) => ReactNode;
};

type DataTableProps<T> = {
  columns: DataTableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  emptyMessage?: string;
  // Optional DOM id per row, separate from the React `key` — lets a
  // caller scroll a specific row into view (e.g. the address book's
  // gojuon index-jump bar) without every consumer needing to care.
  rowId?: (row: T) => string;
};

export default function DataTable<T>({
  columns,
  rows,
  rowKey,
  emptyMessage = "データがありません。",
  rowId,
}: DataTableProps<T>) {
  if (rows.length === 0) {
    return <p className="py-8 text-center text-brand-gray-500">{emptyMessage}</p>;
  }

  return (
    <div className="overflow-x-auto rounded-lg border border-brand-gray-200 bg-white">
      <table className="min-w-full divide-y divide-brand-gray-200">
        <thead className="bg-brand-gray-50">
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                className="px-4 py-3 text-left text-sm font-semibold text-brand-gray-700"
              >
                {column.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-brand-gray-200">
          {rows.map((row) => (
            <tr key={rowKey(row)} id={rowId?.(row)} className="hover:bg-brand-gray-50">
              {columns.map((column) => (
                <td key={column.key} className="px-4 py-3 text-sm text-brand-gray-900">
                  {column.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
