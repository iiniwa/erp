import MenuCard from "@/components/ui/MenuCard";
import { getCurrentUser } from "@/lib/session";

// More cards are added here as each area ships (#7 システム設定).
export default async function MenuPage() {
  const user = await getCurrentUser();
  // Purely a UX nicety (hide cards the user can't do anything with,
  // e.g. a retired employee's default no-access role); the backend's
  // Pundit policies are the actual enforcement point regardless of what
  // renders here.
  const canViewEmployees = user?.permissions.user_manage?.view ?? false;
  const canViewAddresses = user?.permissions.address_book?.view ?? false;
  // Permission management is deliberately not itself governed by
  // t.role_permissions (see PermissionMasterPolicy on the backend), so
  // gating this card on user_type here mirrors that same fixed rule
  // rather than reading it from `permissions`.
  const isSystemAdmin = user?.user_type === "system_admin";

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">メニュー</h1>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {canViewEmployees && (
          <MenuCard
            href="/employees"
            title="従業員管理"
            description="従業員情報の一覧・登録・編集"
          />
        )}
        {canViewAddresses && (
          <MenuCard
            href="/addresses"
            title="アドレス帳"
            description="連絡先の一覧・検索・登録・編集"
          />
        )}
        {isSystemAdmin && (
          <MenuCard
            href="/settings/permissions"
            title="権限管理"
            description="役割ごとの機能アクセス権限の設定"
          />
        )}
      </div>
    </div>
  );
}
