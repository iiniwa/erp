"use client";

import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { updateEmployeeSchema, type UpdateEmployeeFormValues } from "@/lib/validation/employee";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";
import type { Employee } from "@/lib/api/employees";
import type { PermissionRole } from "@/lib/api/permissions";

type Props = { employee: Employee; permissionRoles: PermissionRole[] };

export default function EmployeeEditForm({ employee, permissionRoles }: Props) {
  const router = useRouter();
  const { showToast } = useToast();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<UpdateEmployeeFormValues>({
    resolver: zodResolver(updateEmployeeSchema),
    defaultValues: {
      user_familyname: employee.user_familyname,
      user_firstname: employee.user_firstname,
      user_familyname_ruby: employee.user_familyname_ruby,
      user_firstname_ruby: employee.user_firstname_ruby,
      user_join_date: employee.user_join_date ?? "",
      user_id: employee.user_id ?? "",
      role_id: employee.role_id?.toString() ?? "",
    },
  });

  async function onSubmit(values: UpdateEmployeeFormValues) {
    try {
      const response = await fetch(`/api/employees/${employee.user_code}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...values, role_id: values.role_id || null }),
      });

      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "更新に失敗しました。", "error");
        return;
      }

      showToast("更新しました。");
      router.push(`/employees/${employee.user_code}`);
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <Card className="max-w-xl">
      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            id="user_familyname"
            label="姓"
            error={errors.user_familyname?.message}
            {...register("user_familyname")}
          />
          <Input
            id="user_firstname"
            label="名"
            error={errors.user_firstname?.message}
            {...register("user_firstname")}
          />
          <Input
            id="user_familyname_ruby"
            label="せい（ひらがな）"
            error={errors.user_familyname_ruby?.message}
            {...register("user_familyname_ruby")}
          />
          <Input
            id="user_firstname_ruby"
            label="めい（ひらがな）"
            error={errors.user_firstname_ruby?.message}
            {...register("user_firstname_ruby")}
          />
        </div>
        <Input
          id="user_join_date"
          type="date"
          label="入社日（任意）"
          error={errors.user_join_date?.message}
          {...register("user_join_date")}
        />
        <Input
          id="user_id"
          label="ログインID（任意）"
          error={errors.user_id?.message}
          {...register("user_id")}
        />
        <div>
          <label htmlFor="role_id" className="mb-1 block text-sm font-medium text-brand-gray-700">
            権限ロール（任意）
          </label>
          <select
            id="role_id"
            className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            {...register("role_id")}
          >
            <option value="">未設定</option>
            {permissionRoles.map((role) => (
              <option key={role.role_id} value={role.role_id}>
                {role.role_name}
              </option>
            ))}
          </select>
        </div>
        <Button type="submit" disabled={isSubmitting} className="mt-2">
          {isSubmitting ? "更新中..." : "更新"}
        </Button>
      </form>
    </Card>
  );
}
