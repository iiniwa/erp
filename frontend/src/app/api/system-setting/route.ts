import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export async function GET() {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const response = await backendFetch("/api/v1/system_setting", { sessionToken: token });
  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}

// Forwards the incoming multipart/form-data body as-is (fields + any
// selected logo/favicon/seal files) — see backendFetch's FormData handling
// for why no Content-Type is set manually here.
export async function PATCH(request: Request) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const formData = await request.formData();
  const response = await backendFetch("/api/v1/system_setting", {
    method: "PATCH",
    sessionToken: token,
    body: formData,
  });

  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}
