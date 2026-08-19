import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { clearSessionCookie, getSessionToken } from "@/lib/session";

export async function POST() {
  const token = await getSessionToken();
  if (token) {
    await backendFetch("/api/v1/auth/session", { method: "DELETE", sessionToken: token });
  }
  await clearSessionCookie();

  return NextResponse.json({ ok: true });
}
