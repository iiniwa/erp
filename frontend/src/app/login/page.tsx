"use client";

import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { loginSchema, type LoginFormValues } from "@/lib/validation/auth";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";

function errorMessage(code: string | undefined): string {
  switch (code) {
    case "account_locked":
      return "アカウントがロックされています。管理者にお問い合わせください。";
    case "invalid_credentials":
      return "IDまたは電話番号、パスワードが正しくありません。";
    default:
      return "ログインに失敗しました。時間をおいて再度お試しください。";
  }
}

export default function LoginPage() {
  const router = useRouter();
  const { showToast } = useToast();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({ resolver: zodResolver(loginSchema) });

  async function onSubmit(values: LoginFormValues) {
    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(values),
      });

      if (!response.ok) {
        const body = await response.json().catch(() => ({}));
        showToast(errorMessage(body.error), "error");
        return;
      }

      router.push("/");
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <div className="flex flex-1 items-center justify-center px-4 py-16">
      <Card className="w-full max-w-sm">
        <h1 className="mb-6 text-center text-2xl font-semibold text-brand-gray-900">ログイン</h1>
        <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
          <Input
            id="identifier"
            label="ログインID または 電話番号"
            autoComplete="username"
            error={errors.identifier?.message}
            {...register("identifier")}
          />
          <Input
            id="password"
            type="password"
            label="パスワード"
            autoComplete="current-password"
            error={errors.password?.message}
            {...register("password")}
          />
          <Button type="submit" disabled={isSubmitting} className="mt-2">
            {isSubmitting ? "ログイン中..." : "ログイン"}
          </Button>
        </form>
      </Card>
    </div>
  );
}
