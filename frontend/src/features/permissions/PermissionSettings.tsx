"use client";

import { useState } from "react";
import type { PermissionMaster, PermissionRole, RolePermission } from "@/lib/api/permissions";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Card from "@/components/ui/Card";

type FlagField = "rp_can_view" | "rp_can_create" | "rp_can_update" | "rp_can_delete";
const FLAG_FIELDS: { field: FlagField; label: string }[] = [
  { field: "rp_can_view", label: "閲覧" },
  { field: "rp_can_create", label: "追加" },
  { field: "rp_can_update", label: "編集" },
  { field: "rp_can_delete", label: "削除" },
];

type Props = {
  permissionMasters: PermissionMaster[];
  permissionRoles: PermissionRole[];
  rolePermissions: RolePermission[];
};

export default function PermissionSettings({
  permissionMasters,
  permissionRoles,
  rolePermissions,
}: Props) {
  const { showToast } = useToast();
  const [masters, setMasters] = useState(permissionMasters);
  const [roles, setRoles] = useState(permissionRoles);
  const [rows, setRows] = useState(rolePermissions);
  const [savingId, setSavingId] = useState<number | null>(null);
  const [newCode, setNewCode] = useState("");
  const [newName, setNewName] = useState("");
  const [addingFeature, setAddingFeature] = useState(false);
  const [newRoleName, setNewRoleName] = useState("");
  const [addingRole, setAddingRole] = useState(false);

  async function refetchRolePermissions() {
    const response = await fetch("/api/role-permissions");
    if (!response.ok) {
      showToast("権限一覧の再取得に失敗しました。ページを再読み込みしてください。", "error");
      return;
    }
    const body = await response.json();
    setRows(body.role_permissions);
  }

  async function toggle(cell: RolePermission, field: FlagField) {
    setSavingId(cell.rp_id);
    try {
      const response = await fetch(`/api/role-permissions/${cell.rp_id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ [field]: !cell[field] }),
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "更新に失敗しました。", "error");
        return;
      }
      setRows((prev) => prev.map((row) => (row.rp_id === cell.rp_id ? body.role_permission : row)));
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setSavingId(null);
    }
  }

  async function handleAddFeature() {
    if (!newCode.trim() || !newName.trim()) return;
    setAddingFeature(true);
    try {
      const response = await fetch("/api/permission-masters", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          pm_code: newCode.trim(),
          pm_name: newName.trim(),
          pm_sort: masters.length + 1,
        }),
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "機能の追加に失敗しました。", "error");
        return;
      }
      setMasters((prev) => [...prev, body.permission_master]);
      setNewCode("");
      setNewName("");

      // router.refresh() re-runs the server component but does not
      // remount this already-mounted Client Component, so its useState
      // would keep the stale `rows` (missing the new feature's
      // auto-created role_permissions) forever without this. Refetching
      // directly is simpler than trying to predict the created rows'
      // shape here.
      await refetchRolePermissions();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setAddingFeature(false);
    }
  }

  async function handleDeleteFeature(pmId: number) {
    try {
      const response = await fetch(`/api/permission-masters/${pmId}`, { method: "DELETE" });
      if (!response.ok) {
        showToast("機能の削除に失敗しました。", "error");
        return;
      }
      setMasters((prev) => prev.filter((pm) => pm.pm_id !== pmId));
      setRows((prev) => prev.filter((row) => row.pm_id !== pmId));
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  async function handleAddRole() {
    if (!newRoleName.trim()) return;
    setAddingRole(true);
    try {
      const response = await fetch("/api/permission-roles", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ role_name: newRoleName.trim(), role_sort: roles.length + 1 }),
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "役割の追加に失敗しました。", "error");
        return;
      }
      setRoles((prev) => [...prev, body.permission_role]);
      setNewRoleName("");

      // Same reasoning as handleAddFeature: a new role's auto-created
      // role_permissions rows (one per existing feature) aren't in `rows`
      // yet, so refetch rather than guess their shape.
      await refetchRolePermissions();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setAddingRole(false);
    }
  }

  async function handleDeleteRole(roleId: number) {
    try {
      const response = await fetch(`/api/permission-roles/${roleId}`, { method: "DELETE" });
      if (!response.ok) {
        showToast("役割の削除に失敗しました。", "error");
        return;
      }
      setRoles((prev) => prev.filter((role) => role.role_id !== roleId));
      setRows((prev) => prev.filter((row) => row.role_id !== roleId));
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <h2 className="mb-3 font-medium text-brand-gray-900">役割（権限レベル）の管理</h2>
        <p className="mb-3 text-sm text-brand-gray-500">
          システム管理者は常に全機能へアクセスできます。それ以外の従業員には、ここで作成した役割を割り当てて権限を管理します。
        </p>
        <div className="mb-4 flex flex-wrap gap-2">
          <input
            type="text"
            value={newRoleName}
            onChange={(event) => setNewRoleName(event.target.value)}
            placeholder="役割名（例: 一般スタッフ）"
            className="min-h-11 rounded-md border border-brand-gray-300 px-3 py-2 text-sm focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
          />
          <Button type="button" variant="secondary" disabled={addingRole} onClick={handleAddRole}>
            役割を追加
          </Button>
        </div>
        <ul className="flex flex-wrap gap-2">
          {roles.map((role) => (
            <li
              key={role.role_id}
              className="flex items-center gap-2 rounded-md border border-brand-gray-300 px-3 py-1 text-sm"
            >
              {role.role_name}
              <button
                type="button"
                className="text-red-600 hover:underline"
                onClick={() => handleDeleteRole(role.role_id)}
              >
                削除
              </button>
            </li>
          ))}
        </ul>
      </Card>

      <Card>
        <h2 className="mb-3 font-medium text-brand-gray-900">機能マスタの追加</h2>
        <div className="flex flex-wrap gap-2">
          <input
            type="text"
            value={newCode}
            onChange={(event) => setNewCode(event.target.value)}
            placeholder="機能コード（例: attendance）"
            className="min-h-11 rounded-md border border-brand-gray-300 px-3 py-2 text-sm focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
          />
          <input
            type="text"
            value={newName}
            onChange={(event) => setNewName(event.target.value)}
            placeholder="表示名（例: 勤怠管理）"
            className="min-h-11 rounded-md border border-brand-gray-300 px-3 py-2 text-sm focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
          />
          <Button
            type="button"
            variant="secondary"
            disabled={addingFeature}
            onClick={handleAddFeature}
          >
            追加
          </Button>
        </div>
      </Card>

      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-brand-gray-200 text-sm">
            <thead>
              <tr>
                <th className="px-3 py-2 text-left font-semibold text-brand-gray-700">機能</th>
                {roles.map((role) => (
                  <th
                    key={role.role_id}
                    className="px-3 py-2 text-center font-semibold text-brand-gray-700"
                  >
                    {role.role_name}
                  </th>
                ))}
                <th className="px-3 py-2" />
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-gray-200">
              {masters.map((pm) => (
                <tr key={pm.pm_id}>
                  <td className="px-3 py-2 font-medium text-brand-gray-900">{pm.pm_name}</td>
                  {roles.map((role) => {
                    const cell = rows.find(
                      (row) => row.pm_id === pm.pm_id && row.role_id === role.role_id,
                    );
                    if (!cell) {
                      return (
                        <td
                          key={role.role_id}
                          className="px-3 py-2 text-center text-brand-gray-400"
                        >
                          -
                        </td>
                      );
                    }
                    return (
                      <td key={role.role_id} className="px-3 py-2">
                        <div className="flex flex-col items-center gap-1 text-xs text-brand-gray-700">
                          {FLAG_FIELDS.map(({ field, label }) => (
                            <label key={field} className="flex items-center gap-1">
                              <input
                                type="checkbox"
                                checked={cell[field]}
                                disabled={savingId === cell.rp_id}
                                onChange={() => toggle(cell, field)}
                              />
                              {label}
                            </label>
                          ))}
                        </div>
                      </td>
                    );
                  })}
                  <td className="px-3 py-2 text-right">
                    <Button
                      type="button"
                      variant="danger"
                      onClick={() => handleDeleteFeature(pm.pm_id)}
                    >
                      削除
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
