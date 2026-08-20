import MenuCard from "@/components/ui/MenuCard";

// More cards are added here as each area ships (#5 アドレス帳,
// #6 権限管理, #7 システム設定).
export default function MenuPage() {
  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-brand-gray-900">メニュー</h1>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <MenuCard href="/employees" title="従業員管理" description="従業員情報の一覧・登録・編集" />
      </div>
    </div>
  );
}
