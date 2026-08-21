import type { ReactNode } from "react";
import { notFound } from "next/navigation";
import { fetchAddress } from "@/lib/api/addresses";
import { telLabelText } from "@/lib/validation/address";
import LinkButton from "@/components/ui/LinkButton";
import Card from "@/components/ui/Card";
import AddressActions from "@/features/addresses/AddressActions";

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <dt className="text-sm font-medium text-brand-gray-500">{label}</dt>
      <dd className="mt-1 text-brand-gray-900">{children}</dd>
    </div>
  );
}

function telLabel(tel: { at_label_type: string; at_label_free: string | null }) {
  if (tel.at_label_type === "free") return tel.at_label_free ?? "自由入力";
  return telLabelText[tel.at_label_type] ?? tel.at_label_type;
}

export default async function AddressDetailPage({
  params,
}: {
  params: Promise<{ addressId: string }>;
}) {
  const { addressId } = await params;
  const address = await fetchAddress(addressId);
  if (!address) {
    notFound();
  }

  return (
    <div>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold text-brand-gray-900">{address.address_name}</h1>
        <div className="flex gap-3">
          <LinkButton href={`/addresses/${address.address_id}/edit`} variant="secondary">
            編集
          </LinkButton>
          <LinkButton href="/addresses" variant="secondary">
            一覧に戻る
          </LinkButton>
        </div>
      </div>
      <Card className="mb-6">
        <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Field label="ふりがな">{address.address_ruby}</Field>
          <Field label="カテゴリ">{address.address_category_name}</Field>
          <Field label="担当者名">{address.address_contact_name ?? "未設定"}</Field>
          <Field label="郵便番号">{address.address_post ?? "未設定"}</Field>
          <Field label="住所">{address.address_residence ?? "未設定"}</Field>
          <Field label="備考">{address.address_memo ?? "未設定"}</Field>
        </dl>
      </Card>
      <Card className="mb-6">
        <h2 className="mb-3 font-medium text-brand-gray-900">電話番号</h2>
        {address.address_tels.length === 0 ? (
          <p className="text-sm text-brand-gray-500">登録されていません。</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {address.address_tels.map((tel) => (
              <li key={tel.at_id} className="text-brand-gray-900">
                {tel.at_number}
                <span className="ml-2 text-sm text-brand-gray-500">（{telLabel(tel)}）</span>
              </li>
            ))}
          </ul>
        )}
      </Card>
      <Card className="mb-6">
        <h2 className="mb-3 font-medium text-brand-gray-900">メールアドレス</h2>
        {address.address_emails.length === 0 ? (
          <p className="text-sm text-brand-gray-500">登録されていません。</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {address.address_emails.map((email) => (
              <li key={email.ae_id} className="text-brand-gray-900">
                {email.ae_email}
                {email.ae_label && (
                  <span className="ml-2 text-sm text-brand-gray-500">（{email.ae_label}）</span>
                )}
              </li>
            ))}
          </ul>
        )}
      </Card>
      <AddressActions addressId={address.address_id} />
    </div>
  );
}
