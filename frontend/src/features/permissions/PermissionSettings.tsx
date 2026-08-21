"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { PermissionMaster, RolePermission } from "@/lib/api/permissions";
import { userTypeLabels } from "@/lib/validation/employee";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Card from "@/components/ui/Card";

// Matches RolePermission.rp_user_types' declaration order on the backend
// (system_admin, manager, clerical, general, part_time, retired).
const USER_TYPE_ORDER = ["system_admin", "manager", "clerical", "general", "part_time", "retired"];

type FlagField = "rp_can_view" | "rp_can_create" | "rp_can_update" | "rp_can_delete";
const FLAG_FIELDS: { field: FlagField; label: string }[] = [
  { field: "rp_can_view", label: "閲覧" },
  { field: "rp_can_create", label: "追加" },
  { field: "rp_can_update", label: "編集" },
  { field: "rp_can_delete", label: "削除" },
];

type Props = {
  permissionMasters: PermissionMaster[];
  rolePermissions: RolePermission[];
};

export default function PermissionSettings({ permissionMasters, rolePermissions }: Props) {
  const router = useRouter();
  const { showToast } = useToast();
  const [masters, setMasters] = useState(permissionMasters);
  const [rows, setRows] = useState(rolePermissions);
  const [savingId, setSavingId] = useState<number | null>(null);
  const [newCode, setNewCode] = useState("");
  const [newName, setNewName] = useState("");
  const [addingFeature, setAddingFeature] = useState(false);

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
      router.refresh();
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

  return (
    <div className="flex flex-col gap-6">
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
                {USER_TYPE_ORDER.map((userType) => (
                  <th
                    key={userType}
                    className="px-3 py-2 text-center font-semibold text-brand-gray-700"
                  >
                    {userTypeLabels[userType] ?? userType}
                  </th>
                ))}
                <th className="px-3 py-2" />
              </tr>
            </thead>
            <tbody className="divide-y divide-brand-gray-200">
              {masters.map((pm) => (
                <tr key={pm.pm_id}>
                  <td className="px-3 py-2 font-medium text-brand-gray-900">{pm.pm_name}</td>
                  {USER_TYPE_ORDER.map((userType) => {
                    const cell = rows.find(
                      (row) => row.pm_id === pm.pm_id && row.rp_user_type === userType,
                    );
                    if (!cell) {
                      return (
                        <td key={userType} className="px-3 py-2 text-center text-brand-gray-400">
                          -
                        </td>
                      );
                    }
                    return (
                      <td key={userType} className="px-3 py-2">
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
