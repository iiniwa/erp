import { z } from "zod";

// "区分" is no longer a fixed list: only system_admin is a distinct,
// protected value (spec section 13.1 — exactly one, never picked on the
// edit form). Every other employee is user_type "general" with the
// employee's actual level expressed as a freely admin-managed
// PermissionRole (role_id) — "退職" is excluded entirely, since that
// state is only reachable through the dedicated retire action.
export const KUBUN_SYSTEM_ADMIN = "system_admin";
export const KUBUN_GENERAL = "general";

export const userTypeLabels: Record<string, string> = {
  system_admin: "システム管理者",
  general: "一般",
  retired: "退職",
};

// Decodes the single "区分" select's value into the (user_type, role_id)
// pair the backend expects. Anything other than the two reserved
// sentinels is a PermissionRole's role_id.
export function decodeKubun(kubun: string): {
  user_type: "system_admin" | "general";
  role_id: number | null;
} {
  if (kubun === KUBUN_SYSTEM_ADMIN) {
    return { user_type: "system_admin", role_id: null };
  }
  if (kubun === KUBUN_GENERAL) {
    return { user_type: "general", role_id: null };
  }
  return { user_type: "general", role_id: Number(kubun) };
}

// Inverse of decodeKubun, for pre-filling the edit form's current value.
export function encodeKubun(employee: { user_type: string; role_id: number | null }): string {
  if (employee.user_type === "system_admin") return KUBUN_SYSTEM_ADMIN;
  if (employee.role_id) return employee.role_id.toString();
  return KUBUN_GENERAL;
}

// Display-only label for the employee detail page: the assigned role's
// name takes priority over the generic "一般" bucket label.
export function kubunLabel(employee: { user_type: string; role_name: string | null }): string {
  if (employee.user_type !== "general")
    return userTypeLabels[employee.user_type] ?? employee.user_type;
  return employee.role_name ?? "一般（役割未設定）";
}

const nameFields = {
  user_familyname: z.string().min(1, "姓を入力してください"),
  user_firstname: z.string().min(1, "名を入力してください"),
  user_familyname_ruby: z.string().min(1, "せい（ふりがな）を入力してください"),
  user_firstname_ruby: z.string().min(1, "めい（ふりがな）を入力してください"),
  user_join_date: z.string().optional().or(z.literal("")),
  user_id: z.string().optional().or(z.literal("")),
};

const kubunField = { kubun: z.string().min(1, "区分を選択してください") };

export const createEmployeeSchema = z.object({
  user_birth: z.string().min(1, "生年月日を入力してください"),
  ...nameFields,
  ...kubunField,
});

export type CreateEmployeeFormValues = z.infer<typeof createEmployeeSchema>;

// No user_birth: only used once, to derive the initial password.
export const updateEmployeeSchema = z.object({ ...nameFields, ...kubunField });

export type UpdateEmployeeFormValues = z.infer<typeof updateEmployeeSchema>;
