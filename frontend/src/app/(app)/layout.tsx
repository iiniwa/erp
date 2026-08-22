import type { ReactNode } from "react";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/session";
import { fetchSystemSetting } from "@/lib/api/system-settings";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";

const DEFAULT_SYSTEM_NAME = "ERPシステム";

// SystemSettingsController is gated to system_admin only (see
// SystemSettingPolicy), so a non-system_admin fetch here 403s — that's
// expected, not an error: every signed-in user should still see branding,
// so a failed fetch just falls back to the default name rather than
// breaking the whole layout.
async function fetchSystemName(): Promise<string> {
  try {
    const setting = await fetchSystemSetting();
    return setting?.system_name?.trim() || DEFAULT_SYSTEM_NAME;
  } catch {
    return DEFAULT_SYSTEM_NAME;
  }
}

export default async function AppLayout({ children }: { children: ReactNode }) {
  const user = await getCurrentUser();
  // middleware.ts already enforces this; this is a defense-in-depth
  // fallback for the (unlikely) case a request reaches here without it.
  if (!user) {
    redirect("/login");
  }

  const systemName = await fetchSystemName();

  return (
    <div className="flex min-h-full flex-1 flex-col">
      <Header user={user} systemName={systemName} />
      <main className="mx-auto flex w-full max-w-5xl flex-1 flex-col px-4 py-8">{children}</main>
      <Footer systemName={systemName} />
    </div>
  );
}
