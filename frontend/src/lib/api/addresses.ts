import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export type AddressTel = {
  at_id: number;
  at_number: string;
  at_label_type: string;
  at_label_free: string | null;
  at_sort: number;
};

export type AddressEmail = {
  ae_id: number;
  ae_email: string;
  ae_label: string | null;
  ae_sort: number;
};

export type AddressBookEntry = {
  address_id: string;
  address_category_id: number;
  address_category_name: string;
  address_name: string;
  address_ruby: string;
  address_user_code: string | null;
  address_contact_name: string | null;
  address_post: string | null;
  address_residence: string | null;
  address_memo: string | null;
  address_tels: AddressTel[];
  address_emails: AddressEmail[];
};

export type AddressCategory = { ac_id: number; ac_name: string; ac_sort: number };

// Server-side data fetchers for Server Components. Client Components use
// the /api/addresses BFF routes instead (see lib/backend.ts).
export async function fetchAddresses(): Promise<AddressBookEntry[]> {
  const token = await getSessionToken();
  if (!token) return [];

  const response = await backendFetch("/api/v1/addresses", { sessionToken: token });
  if (!response.ok) return [];

  const body = (await response.json()) as { addresses: AddressBookEntry[] };
  return body.addresses;
}

// Only a real 404 means "no such address" (-> caller should call
// notFound()). Any other failure throws instead of returning null, so it
// doesn't get misread as "not found" (see the equivalent employees fetcher).
export async function fetchAddress(addressId: string): Promise<AddressBookEntry | null> {
  const token = await getSessionToken();
  if (!token) return null;

  const response = await backendFetch(`/api/v1/addresses/${encodeURIComponent(addressId)}`, {
    sessionToken: token,
  });

  if (response.status === 404) return null;
  if (!response.ok) {
    throw new Error(`Failed to fetch address ${addressId} (status ${response.status})`);
  }

  const body = (await response.json()) as { address: AddressBookEntry };
  return body.address;
}

export async function fetchAddressCategories(): Promise<AddressCategory[]> {
  const token = await getSessionToken();
  if (!token) return [];

  const response = await backendFetch("/api/v1/address_categories", { sessionToken: token });
  if (!response.ok) return [];

  const body = (await response.json()) as { address_categories: AddressCategory[] };
  return body.address_categories;
}
