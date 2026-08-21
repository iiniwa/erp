import { fetchAddressCategories } from "@/lib/api/addresses";
import { fetchEmployees } from "@/lib/api/employees";
import AddressForm from "@/features/addresses/AddressForm";

export default async function NewAddressPage() {
  const [categories, employees] = await Promise.all([fetchAddressCategories(), fetchEmployees()]);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">アドレス帳の新規登録</h1>
      <AddressForm mode="create" categories={categories} employees={employees} />
    </div>
  );
}
