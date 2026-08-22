import type { ReactNode } from "react";
import { notFound } from "next/navigation";
import { fetchEmployee } from "@/lib/api/employees";
import { fetchEmployeeAddress } from "@/lib/api/employee-address";
import { userTypeLabels } from "@/lib/validation/employee";
import LinkButton from "@/components/ui/LinkButton";
import Card from "@/components/ui/Card";
import EmployeeActions from "@/features/employees/EmployeeActions";

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <dt className="text-sm font-medium text-brand-gray-500">{label}</dt>
      <dd className="mt-1 text-brand-gray-900">{children}</dd>
    </div>
  );
}

export default async function EmployeeDetailPage({
  params,
}: {
  params: Promise<{ userCode: string }>;
}) {
  const { userCode } = await params;
  const [employee, address] = await Promise.all([
    fetchEmployee(userCode),
    fetchEmployeeAddress(userCode),
  ]);
  if (!employee) {
    notFound();
  }

  return (
    <div>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold text-brand-gray-900">
          {employee.user_familyname} {employee.user_firstname}
        </h1>
        <div className="flex gap-3">
          <LinkButton href={`/employees/${employee.user_code}/edit`} variant="secondary">
            編集
          </LinkButton>
          <LinkButton href="/employees" variant="secondary">
            一覧に戻る
          </LinkButton>
        </div>
      </div>
      <Card className="mb-6">
        <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Field label="ふりがな">
            {employee.user_familyname_ruby} {employee.user_firstname_ruby}
          </Field>
          <Field label="区分">{userTypeLabels[employee.user_type] ?? employee.user_type}</Field>
          <Field label="ログインID">{employee.user_id ?? "未設定"}</Field>
          <Field label="生年月日">{employee.user_birth ?? "未設定"}</Field>
          <Field label="入社日">{employee.user_join_date ?? "未設定"}</Field>
          <Field label="システム登録日">{employee.user_entry_date ?? "未設定"}</Field>
          <Field label="ロック状態">{employee.user_is_locked ? "ロック中" : "ロックなし"}</Field>
        </dl>
      </Card>
      <Card className="mb-6">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-medium text-brand-gray-900">アドレス帳情報</h2>
          <LinkButton href={`/employees/${employee.user_code}/address`} variant="secondary">
            編集
          </LinkButton>
        </div>
        {address ? (
          <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="電話番号">{address.address_tels[0]?.at_number ?? "未登録"}</Field>
            <Field label="メールアドレス">{address.address_emails[0]?.ae_email ?? "未登録"}</Field>
          </dl>
        ) : (
          <p className="text-sm text-brand-gray-500">未登録です。</p>
        )}
      </Card>
      <EmployeeActions userCode={employee.user_code} isRetired={employee.user_type === "retired"} />
    </div>
  );
}
