import { fetchAddresses } from "@/lib/api/addresses";
import AddressSearchList from "@/features/addresses/AddressSearchList";
import LinkButton from "@/components/ui/LinkButton";

export default async function AddressesPage() {
  const addresses = await fetchAddresses();

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-brand-gray-900">アドレス帳</h1>
        <LinkButton href="/addresses/new">新規登録</LinkButton>
      </div>
      <AddressSearchList addresses={addresses} />
    </div>
  );
}
