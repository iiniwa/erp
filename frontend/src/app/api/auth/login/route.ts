import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { setSessionCookie } from "@/lib/session";

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const identifier = typeof body?.identifier === "string" ? body.identifier : null;
  const password = typeof body?.password === "string" ? body.password : null;

  if (!identifier || !password) {
    return NextResponse.json({ error: "invalid_request" }, { status: 400 });
  }

  const response = await backendFetch("/api/v1/auth/session", {
    method: "POST",
    body: JSON.stringify({ identifier, password }),
  });

  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    const error = errorBody.error ?? "unauthorized";
    return NextResponse.json({ error }, { status: response.status });
  }

  const data = await response.json();
  await setSessionCookie(data.session_token);

  return NextResponse.json({ user: data.user });
}
