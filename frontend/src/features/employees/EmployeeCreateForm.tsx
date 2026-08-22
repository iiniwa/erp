"use client";

import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  createEmployeeSchema,
  userTypeOptions,
  type CreateEmployeeFormValues,
} from "@/lib/validation/employee";
import type { PermissionRole } from "@/lib/api/permissions";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";

export default function EmployeeCreateForm({
  permissionRoles,
}: {
  permissionRoles: PermissionRole[];
}) {
  const router = useRouter();
  const { showToast } = useToast();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateEmployeeFormValues>({
    resolver: zodResolver(createEmployeeSchema),
    // No defaultValue for user_type: without an explicit placeholder, a
    // native <select> defaults to its first <option>, which would
    // silently submit "system_admin" (the highest-privilege value) if the
    // user never touches the field. The blank placeholder forces an
    // explicit, validated choice instead.
    defaultValues: { user_type: "" as CreateEmployeeFormValues["user_type"] },
  });

  async function onSubmit(values: CreateEmployeeFormValues) {
    try {
      const response = await fetch("/api/employees", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...values, role_id: values.role_id || null }),
      });

      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "登録に失敗しました。", "error");
        return;
      }

      showToast("従業員を登録しました。");
      router.push(`/employees/${body.user.user_code}`);
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

        <div>
          <label htmlFor="user_type" className="mb-1 block text-sm font-medium text-brand-gray-700">
            区分
          </label>
          <select
            id="user_type"
            className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            {...register("user_type")}
          >
            <option value="">選択してください</option>
            {userTypeOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          {errors.user_type && (
            <p role="alert" className="mt-1 text-sm text-red-600">
              {errors.user_type.message}
            </p>
          )}
        </div>

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

        <Input
          id="user_birth"
          type="date"
          label="生年月日（初期パスワードとして使用されます）"
          error={errors.user_birth?.message}
          {...register("user_birth")}
        />
        <Input
          id="user_join_date"
          type="date"
          label="入社日（任意）"
          error={errors.user_join_date?.message}
          {...register("user_join_date")}
        />
        <Input
          id="user_id"
          label="ログインID（任意・後から設定可能）"
          error={errors.user_id?.message}
          {...register("user_id")}
        />

        <Button type="submit" disabled={isSubmitting} className="mt-2">
          {isSubmitting ? "登録中..." : "登録"}
        </Button>
      </form>
    </Card>
  );
}
