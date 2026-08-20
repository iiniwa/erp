import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

type RouteParams = { params: Promise<{ userCode: string }> };

export async function GET(_request: Request, { params }: RouteParams) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { userCode } = await params;
  const response = await backendFetch(`/api/v1/users/${encodeURIComponent(userCode)}`, {
    sessionToken: token,
  });
  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}

export async function PATCH(request: Request, { params }: RouteParams) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { userCode } = await params;
  const body = await request.json().catch(() => null);
  const response = await backendFetch(`/api/v1/users/${encodeURIComponent(userCode)}`, {
    method: "PATCH",
    sessionToken: token,
    body: JSON.stringify(body),
  });

  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}

export async function DELETE(_request: Request, { params }: RouteParams) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { userCode } = await params;
  const response = await backendFetch(`/api/v1/users/${encodeURIComponent(userCode)}`, {
    method: "DELETE",
    sessionToken: token,
  });

  if (response.status === 204) {
    return new NextResponse(null, { status: 204 });
  }

  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}
