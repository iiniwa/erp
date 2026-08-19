"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LogoutButton() {
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);

  async function handleLogout() {
    setSubmitting(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
      router.push("/login");
      router.refresh();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <button
      type="button"
      onClick={handleLogout}
      disabled={submitting}
      className="rounded-md border border-brand-gray-300 px-4 py-2 font-medium text-brand-gray-700 transition-colors hover:bg-brand-gray-100 disabled:opacity-50"
    >
      {submitting ? "ログアウト中..." : "ログアウト"}
    </button>
  );
}
