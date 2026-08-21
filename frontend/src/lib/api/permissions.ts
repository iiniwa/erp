import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export type PermissionMaster = { pm_id: number; pm_code: string; pm_name: string; pm_sort: number };

export type RolePermission = {
  rp_id: number;
  rp_user_type: string;
  pm_id: number;
  pm_code: string;
  pm_name: string;
  rp_can_view: boolean;
  rp_can_create: boolean;
  rp_can_update: boolean;
  rp_can_delete: boolean;
};

// Server-side data fetchers for Server Components. Only "no session"
// returns an empty list; any other failure (not system_admin, expired
// session, backend error) throws instead of silently rendering an empty
// settings screen.
export async function fetchPermissionMasters(): Promise<PermissionMaster[]> {
  const token = await getSessionToken();
  if (!token) return [];

  const response = await backendFetch("/api/v1/permission_masters", { sessionToken: token });
  if (!response.ok) {
    throw new Error(`Failed to fetch permission masters (status ${response.status})`);
  }

  const body = (await response.json()) as { permission_masters: PermissionMaster[] };
  return body.permission_masters;
}

export async function fetchRolePermissions(): Promise<RolePermission[]> {
  const token = await getSessionToken();
  if (!token) return [];

  const response = await backendFetch("/api/v1/role_permissions", { sessionToken: token });
  if (!response.ok) {
    throw new Error(`Failed to fetch role permissions (status ${response.status})`);
  }

  const body = (await response.json()) as { role_permissions: RolePermission[] };
  return body.role_permissions;
}
