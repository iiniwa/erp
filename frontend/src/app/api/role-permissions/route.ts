import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export async function GET() {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const response = await backendFetch("/api/v1/role_permissions", { sessionToken: token });
  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}
