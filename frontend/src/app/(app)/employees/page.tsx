import Link from "next/link";
import { fetchEmployees, type Employee } from "@/lib/api/employees";
import { userTypeLabels } from "@/lib/validation/employee";
import DataTable, { type DataTableColumn } from "@/components/ui/DataTable";
import LinkButton from "@/components/ui/LinkButton";

export default async function EmployeesPage() {
  const employees = await fetchEmployees();

  const columns: DataTableColumn<Employee>[] = [
    {
      key: "name",
      header: "氏名",
      render: (employee) => (
        <Link
          href={`/employees/${employee.user_code}`}
          className="text-brand-green-700 hover:underline"
        >
          {employee.user_familyname} {employee.user_firstname}
        </Link>
      ),
    },
    {
      key: "user_type",
      header: "区分",
      render: (employee) => userTypeLabels[employee.user_type] ?? employee.user_type,
    },
    {
      key: "user_id",
      header: "ログインID",
      render: (employee) => employee.user_id ?? "未設定",
    },
    {
      key: "user_is_locked",
      header: "状態",
      render: (employee) => (employee.user_is_locked ? "ロック中" : ""),
    },
  ];

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-brand-gray-900">従業員管理</h1>
        <LinkButton href="/employees/new">新規登録</LinkButton>
      </div>
      <DataTable
        columns={columns}
        rows={employees}
        rowKey={(employee) => employee.user_code}
        emptyMessage="登録されている従業員がいません。"
      />
    </div>
  );
}
