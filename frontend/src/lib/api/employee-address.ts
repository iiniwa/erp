import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";
import type { AddressTel, AddressEmail } from "@/lib/api/addresses";

export type EmployeeAddress = {
  address_id: string | null;
  address_name: string;
  address_ruby: string;
  address_contact_name: string | null;
  address_post: string | null;
  address_residence: string | null;
  address_memo: string | null;
  address_tels: AddressTel[];
  address_emails: AddressEmail[];
};

// Server-side data fetcher for the Server Component page. Unlike
// fetchAddress, there is no 404 case: Api::V1::EmployeeAddressesController#show
// always returns something, lazily building an unsaved default entry
// (address_id: null) if the employee has no address yet.
export async function fetchEmployeeAddress(userCode: string): Promise<EmployeeAddress | null> {
  const token = await getSessionToken();
  if (!token) return null;

  const response = await backendFetch(`/api/v1/users/${encodeURIComponent(userCode)}/address`, {
    sessionToken: token,
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch employee address for ${userCode} (status ${response.status})`);
  }

  const body = (await response.json()) as { address: EmployeeAddress };
  return body.address;
}
