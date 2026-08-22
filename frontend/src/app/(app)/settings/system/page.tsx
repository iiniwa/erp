import { redirect } from "next/navigation";
import { fetchSystemSetting } from "@/lib/api/system-settings";
import { getCurrentUser } from "@/lib/session";
import SystemSettingsForm from "@/features/system-settings/SystemSettingsForm";

export default async function SystemSettingsPage() {
  const user = await getCurrentUser();
  // Backend (SystemSettingPolicy) is the real enforcement point and would
  // 403 either way; this redirect just avoids surfacing a generic error
  // page to someone who simply navigated here without the system_admin role.
  if (user?.user_type !== "system_admin") {
    redirect("/");
  }

  const setting = await fetchSystemSetting();
  if (!setting) {
    redirect("/");
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">システム・自社情報</h1>
      <SystemSettingsForm setting={setting} />
    </div>
  );
}
