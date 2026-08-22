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

// Matches FileStorageService::MAX_UPLOAD_SIZE on the backend (the real
// enforcement point, since Rails reads the whole upload into memory
// there); rejecting an oversized request here too avoids buffering it
// into a FormData object first just to have Rails reject it anyway.
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;

// Forwards the incoming multipart/form-data body as-is (fields + any
// selected logo/favicon/seal files) — see backendFetch's FormData handling
// for why no Content-Type is set manually here.
export async function PATCH(request: Request) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const contentLength = Number(request.headers.get("content-length") ?? 0);
  if (contentLength > MAX_UPLOAD_BYTES) {
    return NextResponse.json({ error: "payload_too_large" }, { status: 413 });
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
