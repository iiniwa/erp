import EmployeeCreateForm from "@/features/employees/EmployeeCreateForm";

export default function NewEmployeePage() {
  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">従業員の新規登録</h1>
      <EmployeeCreateForm />
    </div>
  );
}
