import { redirect } from "next/navigation";
import { fetchPermissionMasters, fetchRolePermissions } from "@/lib/api/permissions";
import { getCurrentUser } from "@/lib/session";
import PermissionSettings from "@/features/permissions/PermissionSettings";

export default async function PermissionSettingsPage() {
  const user = await getCurrentUser();
  // Backend (PermissionMasterPolicy/RolePermissionPolicy) is the real
  // enforcement point and would 403 either way; this redirect just
  // avoids surfacing a generic error page to someone who simply
  // navigated here without the system_admin role.
  if (user?.user_type !== "system_admin") {
    redirect("/");
  }

  const [permissionMasters, rolePermissions] = await Promise.all([
    fetchPermissionMasters(),
    fetchRolePermissions(),
  ]);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">権限管理</h1>
      <PermissionSettings permissionMasters={permissionMasters} rolePermissions={rolePermissions} />
    </div>
  );
}
