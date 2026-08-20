import type { ReactNode } from "react";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/session";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";

export default async function AppLayout({ children }: { children: ReactNode }) {
  const user = await getCurrentUser();
  // middleware.ts already enforces this; this is a defense-in-depth
  // fallback for the (unlikely) case a request reaches here without it.
  if (!user) {
    redirect("/login");
  }

  return (
    <div className="flex min-h-full flex-1 flex-col">
      <Header user={user} />
      <main className="mx-auto flex w-full max-w-5xl flex-1 flex-col px-4 py-8">{children}</main>
      <Footer />
    </div>
  );
}
