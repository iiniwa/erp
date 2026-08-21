import { fetchPermissionMasters, fetchRolePermissions } from "@/lib/api/permissions";
import PermissionSettings from "@/features/permissions/PermissionSettings";

export default async function PermissionSettingsPage() {
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
