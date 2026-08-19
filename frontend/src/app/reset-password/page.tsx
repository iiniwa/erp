"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    if (password.length < 4) {
      setError("パスワードは4文字以上で入力してください。");
      return;
    }
    if (password !== confirmation) {
      setError("パスワードが一致しません。");
      return;
    }

    setSubmitting(true);
    try {
      const response = await fetch("/api/auth/password", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ password }),
      });

      if (!response.ok) {
        setError("パスワードの変更に失敗しました。時間をおいて再度お試しください。");
        return;
      }

      router.push("/");
      router.refresh();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex flex-1 items-center justify-center px-4 py-16">
      <div className="w-full max-w-sm rounded-lg border border-brand-gray-200 bg-white p-8 shadow-sm">
        <h1 className="mb-2 text-center text-2xl font-semibold text-brand-gray-900">
          パスワードの再設定
        </h1>
        <p className="mb-6 text-center text-sm text-brand-gray-600">
          初回ログインのため、新しいパスワードを設定してください。
        </p>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <label htmlFor="password" className="mb-1 block text-sm font-medium text-brand-gray-700">
              新しいパスワード（4文字以上）
            </label>
            <input
              id="password"
              name="password"
              type="password"
              autoComplete="new-password"
              required
              minLength={4}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            />
          </div>
          <div>
            <label
              htmlFor="confirmation"
              className="mb-1 block text-sm font-medium text-brand-gray-700"
            >
              新しいパスワード（確認）
            </label>
            <input
              id="confirmation"
              name="confirmation"
              type="password"
              autoComplete="new-password"
              required
              minLength={4}
              value={confirmation}
              onChange={(event) => setConfirmation(event.target.value)}
              className="w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            />
          </div>
          {error && (
            <p role="alert" className="text-sm text-red-600">
              {error}
            </p>
          )}
          <button
            type="submit"
            disabled={submitting}
            className="mt-2 rounded-md bg-brand-green-600 px-4 py-2 font-medium text-white transition-colors hover:bg-brand-green-700 disabled:opacity-50"
          >
            {submitting ? "変更中..." : "パスワードを変更"}
          </button>
        </form>
      </div>
    </div>
  );
}
