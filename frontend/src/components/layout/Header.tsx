"use client";

import { useCallback, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Modal from "@/components/ui/Modal";
import { useToast } from "@/components/ui/ToastProvider";
import type { CurrentUser } from "@/lib/session";

export default function Header({ user }: { user: CurrentUser }) {
  const router = useRouter();
  const { showToast } = useToast();
  const [confirmingLogout, setConfirmingLogout] = useState(false);

  // Stable identity: Modal's focus-trap effect depends on this, and an
  // inline arrow function here would give it a new identity on every
  // Header re-render, re-triggering the effect and stealing focus back.
  const closeLogoutModal = useCallback(() => setConfirmingLogout(false), []);

  async function handleLogout() {
    try {
      const response = await fetch("/api/auth/logout", { method: "POST" });
      if (!response.ok) {
        showToast("ログアウトに失敗しました。時間をおいて再度お試しください。", "error");
        return;
      }
      router.push("/login");
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setConfirmingLogout(false);
    }
  }

  return (
    <header className="border-b border-brand-gray-200 bg-white">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
        <Link href="/" className="text-lg font-semibold text-brand-gray-900">
          ERPシステム
        </Link>
        <div className="flex items-center gap-4">
          <span className="text-sm text-brand-gray-700">
            {user.user_familyname} {user.user_firstname} さん
          </span>
          <button
            type="button"
            onClick={() => setConfirmingLogout(true)}
            className="min-h-11 rounded-md border border-brand-gray-300 px-4 py-2 text-sm font-medium text-brand-gray-700 transition-colors hover:bg-brand-gray-100"
          >
            ログアウト
          </button>
        </div>
      </div>
      <Modal
        open={confirmingLogout}
        title="ログアウトの確認"
        onConfirm={handleLogout}
        onCancel={closeLogoutModal}
        confirmLabel="ログアウト"
      >
        ログアウトしてもよろしいですか？
      </Modal>
    </header>
  );
}
