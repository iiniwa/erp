import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export async function PATCH(request: Request) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const body = await request.json().catch(() => null);
  const password = typeof body?.password === "string" ? body.password : null;
  if (!password) {
    return NextResponse.json({ error: "invalid_request" }, { status: 400 });
  }

  const response = await backendFetch("/api/v1/auth/password", {
    method: "PATCH",
    sessionToken: token,
    body: JSON.stringify({ password }),
  });

  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}
