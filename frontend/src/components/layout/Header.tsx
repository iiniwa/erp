"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Modal from "@/components/ui/Modal";
import type { CurrentUser } from "@/lib/session";

export default function Header({ user }: { user: CurrentUser }) {
  const router = useRouter();
  const [confirmingLogout, setConfirmingLogout] = useState(false);

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
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
        onCancel={() => setConfirmingLogout(false)}
        confirmLabel="ログアウト"
      >
        ログアウトしてもよろしいですか？
      </Modal>
    </header>
  );
}
