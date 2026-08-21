import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

type RouteParams = { params: Promise<{ addressId: string }> };

export async function GET(_request: Request, { params }: RouteParams) {
  const token = await getSessionToken();
  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const { addressId } = await params;
  const response = await backendFetch(`/api/v1/addresses/${encodeURIComponent(addressId)}`, {
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

  const { addressId } = await params;
  const body = await request.json().catch(() => null);
  const response = await backendFetch(`/api/v1/addresses/${encodeURIComponent(addressId)}`, {
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

  const { addressId } = await params;
  const response = await backendFetch(`/api/v1/addresses/${encodeURIComponent(addressId)}`, {
    method: "DELETE",
    sessionToken: token,
  });

  if (response.status === 204) {
    return new NextResponse(null, { status: 204 });
  }

  const data = await response.json().catch(() => ({}));
  return NextResponse.json(data, { status: response.status });
}
