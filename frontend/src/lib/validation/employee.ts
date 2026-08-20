import { z } from "zod";

// Excludes "retired": that state is only reachable through the dedicated
// retire action (spec section 5.1), never picked directly on a form.
export const USER_TYPE_VALUES = [
  "system_admin",
  "manager",
  "clerical",
  "general",
  "part_time",
] as const;

export const userTypeOptions: { value: (typeof USER_TYPE_VALUES)[number]; label: string }[] = [
  { value: "system_admin", label: "システム管理者" },
  { value: "manager", label: "管理職" },
  { value: "clerical", label: "事務職" },
  { value: "general", label: "一般" },
  { value: "part_time", label: "非常勤" },
];

export const userTypeLabels: Record<string, string> = {
  system_admin: "システム管理者",
  manager: "管理職",
  clerical: "事務職",
  general: "一般",
  part_time: "非常勤",
  retired: "退職",
};

const nameFields = {
  user_familyname: z.string().min(1, "姓を入力してください"),
  user_firstname: z.string().min(1, "名を入力してください"),
  user_familyname_ruby: z.string().min(1, "せい（ふりがな）を入力してください"),
  user_firstname_ruby: z.string().min(1, "めい（ふりがな）を入力してください"),
  user_join_date: z.string().optional().or(z.literal("")),
  user_id: z.string().optional().or(z.literal("")),
};

export const createEmployeeSchema = z.object({
  user_type: z.enum(USER_TYPE_VALUES),
  user_birth: z.string().min(1, "生年月日を入力してください"),
  ...nameFields,
});

export type CreateEmployeeFormValues = z.infer<typeof createEmployeeSchema>;

// No user_type/user_birth: retirement goes through its own action, and
// the birthdate is only used once, to derive the initial password.
export const updateEmployeeSchema = z.object(nameFields);

export type UpdateEmployeeFormValues = z.infer<typeof updateEmployeeSchema>;
