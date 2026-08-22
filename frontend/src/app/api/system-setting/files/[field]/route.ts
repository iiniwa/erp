import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

type RouteParams = { params: Promise<{ field: string }> };

// Streams a logo/favicon/seal's raw bytes back to the browser — the file
// itself lives in SFTPGo, which the browser can't reach directly (see
// FileStorageService and Api::V1::SystemSettingsController#file).
export async function GET(_request: Request, { params }: RouteParams) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { field } = await params;
  const response = await backendFetch(`/api/v1/system_setting/files/${encodeURIComponent(field)}`, {
    sessionToken: token,
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    return NextResponse.json(data, { status: response.status });
  }

  const buffer = await response.arrayBuffer();
  return new NextResponse(buffer, {
    headers: { "Content-Type": response.headers.get("content-type") ?? "application/octet-stream" },
  });
}
