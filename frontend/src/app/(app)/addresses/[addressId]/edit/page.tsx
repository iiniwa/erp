import { notFound, redirect } from "next/navigation";
import { fetchAddress, fetchAddressCategories } from "@/lib/api/addresses";
import AddressForm from "@/features/addresses/AddressForm";

export default async function EditAddressPage({
  params,
}: {
  params: Promise<{ addressId: string }>;
}) {
  const { addressId } = await params;
  const [address, categories] = await Promise.all([
    fetchAddress(addressId),
    fetchAddressCategories(),
  ]);

  if (!address) {
    notFound();
  }

  // Employee-linked addresses can only be edited from Employee Management
  // (spec-following decision: the employee<->address_book linkage must
  // not be changeable from here) — the backend rejects this too, but
  // redirecting avoids surfacing a generic error page.
  if (address.address_user_code) {
    redirect(`/addresses/${address.address_id}`);
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">アドレス帳の編集</h1>
      <AddressForm mode="edit" address={address} categories={categories} />
    </div>
  );
}
