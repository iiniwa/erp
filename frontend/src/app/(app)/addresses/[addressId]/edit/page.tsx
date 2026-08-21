import { notFound } from "next/navigation";
import { fetchAddress, fetchAddressCategories } from "@/lib/api/addresses";
import { fetchEmployees } from "@/lib/api/employees";
import AddressForm from "@/features/addresses/AddressForm";

export default async function EditAddressPage({
  params,
}: {
  params: Promise<{ addressId: string }>;
}) {
  const { addressId } = await params;
  const [address, categories, employees] = await Promise.all([
    fetchAddress(addressId),
    fetchAddressCategories(),
    fetchEmployees(),
  ]);

  if (!address) {
    notFound();
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">アドレス帳の編集</h1>
      <AddressForm mode="edit" address={address} categories={categories} employees={employees} />
    </div>
  );
}
