import { notFound } from "next/navigation";
import { fetchEmployee } from "@/lib/api/employees";
import { fetchEmployeeAddress } from "@/lib/api/employee-address";
import EmployeeAddressForm from "@/features/employees/EmployeeAddressForm";

export default async function EmployeeAddressPage({
  params,
}: {
  params: Promise<{ userCode: string }>;
}) {
  const { userCode } = await params;
  const [employee, address] = await Promise.all([
    fetchEmployee(userCode),
    fetchEmployeeAddress(userCode),
  ]);

  if (!employee || !address) {
    notFound();
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">
        {employee.user_familyname} {employee.user_firstname} のアドレス帳情報
      </h1>
      <EmployeeAddressForm userCode={userCode} address={address} />
    </div>
  );
}
