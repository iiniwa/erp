import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

type RouteParams = { params: Promise<{ userCode: string }> };

export async function POST(_request: Request, { params }: RouteParams) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { userCode } = await params;
  const response = await backendFetch(`/api/v1/users/${encodeURIComponent(userCode)}/retire`, {
    method: "POST",
    sessionToken: token,
  });

  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}
