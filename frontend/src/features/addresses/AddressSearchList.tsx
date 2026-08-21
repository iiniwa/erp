"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { AddressBookEntry } from "@/lib/api/addresses";
import { normalizeForSearch } from "@/lib/kana";
import DataTable, { type DataTableColumn } from "@/components/ui/DataTable";
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

export default function AddressSearchList({ addresses }: { addresses: AddressBookEntry[] }) {
  const [query, setQuery] = useState("");

  const filtered = useMemo(
    () => addresses.filter((address) => matchesQuery(address, query)),
    [addresses, query],
  );

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
    { key: "category", header: "カテゴリ", render: (address) => address.address_category_name },
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
    {
      key: "contact",
      header: "担当者名",
      render: (address) => address.address_contact_name ?? "",
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
      <DataTable
        columns={columns}
        rows={filtered}
        rowKey={(address) => address.address_id}
        emptyMessage="該当するアドレス帳データがありません。"
      />
    </div>
  );
}
