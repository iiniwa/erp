"use client";

import { GOJUON_ROWS } from "@/lib/kana";

// Issue #33: あ・か・さ・た・な... skip buttons. `rowTargets` maps a
// gojuon row label to the DOM id of the first matching entry in the
// current (sorted + filtered) list; a row with no match in the current
// view is rendered disabled rather than omitted, so the bar's shape stays
// stable as the search query changes.
export default function GojuonIndexBar({ rowTargets }: { rowTargets: Map<string, string> }) {
  function jumpTo(targetId: string | undefined) {
    if (!targetId) return;
    document.getElementById(targetId)?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  return (
    <div className="mb-4 flex flex-wrap gap-1" role="navigation" aria-label="五十音インデックス">
      {GOJUON_ROWS.map((row) => {
        const targetId = rowTargets.get(row.label);
        return (
          <button
            key={row.label}
            type="button"
            disabled={!targetId}
            onClick={() => jumpTo(targetId)}
            className="min-h-9 min-w-9 rounded-md border border-brand-gray-300 px-2 text-sm font-medium text-brand-gray-700 transition-colors hover:bg-brand-gray-100 disabled:cursor-not-allowed disabled:border-brand-gray-100 disabled:text-brand-gray-300 disabled:hover:bg-transparent"
          >
            {row.label}
          </button>
        );
      })}
    </div>
  );
}
