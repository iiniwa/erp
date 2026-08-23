import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export type Employee = {
  user_code: string;
  user_id: string | null;
  user_type: string;
  role_id: number | null;
  role_name: string | null;
  user_familyname: string;
  user_firstname: string;
  user_familyname_ruby: string;
  user_firstname_ruby: string;
  user_birth: string | null;
  user_join_date: string | null;
  user_entry_date: string | null;
  user_is_locked: boolean;
  user_must_change_password: boolean;
};

// Server-side data fetchers for Server Components (list/detail pages).
// Client Components talk to the /api/employees BFF routes instead, since
// they can't read the httpOnly session cookie directly.
export async function fetchEmployees(): Promise<Employee[]> {
  const token = await getSessionToken();
  if (!token) return [];

  const response = await backendFetch("/api/v1/users", { sessionToken: token });
  if (!response.ok) return [];

  const body = (await response.json()) as { users: Employee[] };
  return body.users;
}

// Only a real 404 means "no such employee" (-> caller should call
// notFound()). Any other failure (expired session, backend error) throws
// instead, so it surfaces as a proper error rather than a misleading 404.
export async function fetchEmployee(userCode: string): Promise<Employee | null> {
  const token = await getSessionToken();
  if (!token) return null;

  const response = await backendFetch(`/api/v1/users/${encodeURIComponent(userCode)}`, {
    sessionToken: token,
  });

  if (response.status === 404) return null;
  if (!response.ok) {
    throw new Error(`Failed to fetch employee ${userCode} (status ${response.status})`);
  }

  const body = (await response.json()) as { user: Employee };
  return body.user;
}
