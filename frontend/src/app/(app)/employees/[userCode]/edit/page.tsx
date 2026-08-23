import { notFound } from "next/navigation";
import { fetchEmployee } from "@/lib/api/employees";
import { fetchEmployeeAddress } from "@/lib/api/employee-address";
import { fetchPermissionRoles } from "@/lib/api/permissions";
import EmployeeEditForm from "@/features/employees/EmployeeEditForm";

export default async function EditEmployeePage({
  params,
}: {
  params: Promise<{ userCode: string }>;
}) {
  const { userCode } = await params;
  const [employee, address, permissionRoles] = await Promise.all([
    fetchEmployee(userCode),
    fetchEmployeeAddress(userCode),
    fetchPermissionRoles(),
  ]);
  if (!employee || !address) {
    notFound();
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">従業員情報の編集</h1>
      <EmployeeEditForm employee={employee} address={address} permissionRoles={permissionRoles} />
    </div>
  );
}
