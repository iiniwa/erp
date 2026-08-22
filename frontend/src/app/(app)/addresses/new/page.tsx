import { fetchAddressCategories } from "@/lib/api/addresses";
import AddressForm from "@/features/addresses/AddressForm";

export default async function NewAddressPage() {
  const categories = await fetchAddressCategories();

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">アドレス帳の新規登録</h1>
      <AddressForm mode="create" categories={categories} />
    </div>
  );
}
