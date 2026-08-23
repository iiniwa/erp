"use client";

import { GOJUON_ROWS } from "@/lib/kana";

// Issue #33: あ・か・さ・た・な... skip buttons. A row with no match in
// the current (sorted + filtered) view is rendered disabled rather than
// omitted, so the bar's shape stays stable as the search query changes.
// Jumping is delegated to the caller: it alone knows which of the
// table/card DOM ids for a given row is actually visible right now.
export default function GojuonIndexBar({
  availableLabels,
  onJump,
}: {
  availableLabels: Set<string>;
  onJump: (label: string) => void;
}) {
  return (
    <div className="mb-4 flex flex-wrap gap-1" role="navigation" aria-label="五十音インデックス">
      {GOJUON_ROWS.map((row) => {
        const available = availableLabels.has(row.label);
        return (
          <button
            key={row.label}
            type="button"
            disabled={!available}
            onClick={() => onJump(row.label)}
            className="min-h-9 min-w-9 rounded-md border border-brand-gray-300 px-2 text-sm font-medium text-brand-gray-700 transition-colors hover:bg-brand-gray-100 disabled:cursor-not-allowed disabled:border-brand-gray-100 disabled:text-brand-gray-300 disabled:hover:bg-transparent"
          >
            {row.label}
          </button>
        );
      })}
    </div>
  );
}
