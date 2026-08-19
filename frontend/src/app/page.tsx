import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/session";
import LogoutButton from "@/components/ui/LogoutButton";

export default async function Home() {
  const user = await getCurrentUser();
  // middleware.ts already enforces this; this is a defense-in-depth
  // fallback for the (unlikely) case a request reaches here without it.
  if (!user) {
    redirect("/login");
  }

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-6 px-4 py-16">
      <h1 className="text-2xl font-semibold text-brand-gray-900">
        ようこそ、{user.user_familyname} {user.user_firstname} さん
      </h1>
      <LogoutButton />
    </div>
  );
}
