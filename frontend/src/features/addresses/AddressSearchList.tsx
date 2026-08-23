"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { AddressBookEntry } from "@/lib/api/addresses";
import { compareByRuby, gojuonRowLabel, normalizeForSearch } from "@/lib/kana";
import DataTable, { type DataTableColumn } from "@/components/ui/DataTable";
import DataCardList from "@/components/ui/DataCardList";
import GojuonIndexBar from "@/features/addresses/GojuonIndexBar";
import Input from "@/components/ui/Input";

// Spec section 6: search runs entirely client-side against the full
// #index payload (small dataset: a handful of employees + business
// contacts), matching if the query appears in any of the listed fields.
function matchesQuery(address: AddressBookEntry, query: string): boolean {
  if (!query) return true;

  const normalizedQuery = normalizeForSearch(query);
  const haystacks = [
    address.address_name,
    address.address_ruby,
    address.address_contact_name ?? "",
    ...address.address_tels.map((tel) => tel.at_number),
    ...address.address_emails.map((email) => email.ae_email),
  ];

  return haystacks.some((value) => normalizeForSearch(value).includes(normalizedQuery));
}

function rowDomId(address: AddressBookEntry) {
  return `address-row-${address.address_id}`;
}

export default function AddressSearchList({ addresses }: { addresses: AddressBookEntry[] }) {
  const [query, setQuery] = useState("");

  // Issue #33: あいうえお順 (gojuon order) by ふりがな, both for display
  // and as the basis the index-jump bar scrolls within.
  const sorted = useMemo(
    () => [...addresses].sort((a, b) => compareByRuby(a.address_ruby, b.address_ruby)),
    [addresses],
  );

  const filtered = useMemo(
    () => sorted.filter((address) => matchesQuery(address, query)),
    [sorted, query],
  );

  // First entry in the current (sorted + filtered) list for each gojuon
  // row, so the index bar jumps to whatever is actually visible right now
  // rather than a position from the unfiltered list.
  const rowTargets = useMemo(() => {
    const targets = new Map<string, string>();
    for (const address of filtered) {
      const label = gojuonRowLabel(address.address_ruby);
      if (label && !targets.has(label)) {
        targets.set(label, rowDomId(address));
      }
    }
    return targets;
  }, [filtered]);

  const columns: DataTableColumn<AddressBookEntry>[] = [
    {
      key: "name",
      header: "名称",
      render: (address) => (
        <Link
          href={`/addresses/${address.address_id}`}
          className="text-brand-green-700 hover:underline"
        >
          {address.address_name}
        </Link>
      ),
    },
    {
      key: "contact",
      header: "担当者名",
      render: (address) => address.address_contact_name ?? "",
    },
    {
      key: "tel",
      header: "電話番号",
      render: (address) => address.address_tels[0]?.at_number ?? "",
    },
    {
      key: "email",
      header: "メールアドレス",
      render: (address) => address.address_emails[0]?.ae_email ?? "",
    },
  ];

  return (
    <div>
      <div className="mb-4 max-w-sm">
        <Input
          id="address-search"
          label="検索（氏名・ふりがな・電話番号・メールアドレス・担当者名）"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="キーワードを入力"
        />
      </div>
      <GojuonIndexBar rowTargets={rowTargets} />
      {/* PC: table. Phone-width: one card per entry (same columns). */}
      <div className="hidden sm:block">
        <DataTable
          columns={columns}
          rows={filtered}
          rowKey={(address) => address.address_id}
          rowId={rowDomId}
          emptyMessage="該当するアドレス帳データがありません。"
        />
      </div>
      <div className="sm:hidden">
        <DataCardList
          columns={columns}
          rows={filtered}
          rowKey={(address) => address.address_id}
          rowId={rowDomId}
          emptyMessage="該当するアドレス帳データがありません。"
        />
      </div>
    </div>
  );
}
