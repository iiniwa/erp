import { NextRequest, NextResponse } from "next/server";

// Delegates the actual auth/password-reset-required decision to
// Api::V1::MeController (200 = fully authenticated, 403 =
// user_must_change_password, 401 = no/invalid session) so the rule lives
// in exactly one place instead of being duplicated here.
const LOGIN_PATH = "/login";
const PASSWORD_RESET_PATH = "/reset-password";
const SESSION_COOKIE_NAME = "session_token";

async function fetchMeStatus(token: string | undefined): Promise<number> {
  if (!token) return 401;

  const backendUrl = process.env.BACKEND_INTERNAL_URL ?? "http://backend:3000";
  const internalSecret = process.env.INTERNAL_API_SECRET ?? "";

  const response = await fetch(`${backendUrl}/api/v1/me`, {
    headers: {
      "X-Internal-Api-Secret": internalSecret,
      Authorization: `Bearer ${token}`,
    },
    cache: "no-store",
  });

  return response.status;
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const token = request.cookies.get(SESSION_COOKIE_NAME)?.value;
  const status = await fetchMeStatus(token);

  const isLoginPath = pathname === LOGIN_PATH;
  const isPasswordResetPath = pathname === PASSWORD_RESET_PATH;

  if (status === 200) {
    if (isLoginPath || isPasswordResetPath) {
      return NextResponse.redirect(new URL("/", request.url));
    }
    return NextResponse.next();
  }

  if (status === 403) {
    if (isPasswordResetPath) {
      return NextResponse.next();
    }
    return NextResponse.redirect(new URL(PASSWORD_RESET_PATH, request.url));
  }

  if (isLoginPath) {
    return NextResponse.next();
  }
  return NextResponse.redirect(new URL(LOGIN_PATH, request.url));
}

export const config = {
  // manifest.json/sw.js/icons must stay reachable unauthenticated: the
  // browser fetches them directly (not via our fetch() calls), so a
  // redirect to /login would hand back that page's HTML where JSON (or
  // the service worker script) was expected.
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|manifest.json|sw.js|icon-192.png|icon-512.png|icon.svg).*)",
  ],
};
