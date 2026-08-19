"use client";

import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { passwordSchema, type PasswordFormValues } from "@/lib/validation/auth";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";

export default function ResetPasswordPage() {
  const router = useRouter();
  const { showToast } = useToast();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<PasswordFormValues>({ resolver: zodResolver(passwordSchema) });

  async function onSubmit(values: PasswordFormValues) {
    try {
      const response = await fetch("/api/auth/password", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ password: values.password }),
      });

      if (!response.ok) {
        showToast("パスワードの変更に失敗しました。時間をおいて再度お試しください。", "error");
        return;
      }

      showToast("パスワードを変更しました。");
      router.push("/");
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <div className="flex flex-1 items-center justify-center px-4 py-16">
      <Card className="w-full max-w-sm">
        <h1 className="mb-2 text-center text-2xl font-semibold text-brand-gray-900">
          パスワードの再設定
        </h1>
        <p className="mb-6 text-center text-sm text-brand-gray-600">
          初回ログインのため、新しいパスワードを設定してください。
        </p>
        <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
          <Input
            id="password"
            type="password"
            label="新しいパスワード（4文字以上）"
            autoComplete="new-password"
            error={errors.password?.message}
            {...register("password")}
          />
          <Input
            id="confirmation"
            type="password"
            label="新しいパスワード（確認）"
            autoComplete="new-password"
            error={errors.confirmation?.message}
            {...register("confirmation")}
          />
          <Button type="submit" disabled={isSubmitting} className="mt-2">
            {isSubmitting ? "変更中..." : "パスワードを変更"}
          </Button>
        </form>
      </Card>
    </div>
  );
}
