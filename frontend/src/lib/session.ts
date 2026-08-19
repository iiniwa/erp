import { cookies } from "next/headers";
import { backendFetch } from "@/lib/backend";

// Holds the opaque token Rails issued (Session.issue_for); the actual
// session record lives in t.sessions, not in this cookie (spec section
// 3.5: DB session, not JWT). Rails' Session::DEFAULT_TTL is 12 hours, so
// the cookie is kept in sync rather than outliving the server-side session.
export const SESSION_COOKIE_NAME = "session_token";
const SESSION_COOKIE_MAX_AGE_SECONDS = 60 * 60 * 12;

export async function setSessionCookie(token: string) {
  const cookieStore = await cookies();
  cookieStore.set(SESSION_COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: SESSION_COOKIE_MAX_AGE_SECONDS,
  });
}

export async function clearSessionCookie() {
  const cookieStore = await cookies();
  cookieStore.delete(SESSION_COOKIE_NAME);
}

export async function getSessionToken() {
  const cookieStore = await cookies();
  return cookieStore.get(SESSION_COOKIE_NAME)?.value ?? null;
}

export type CurrentUser = {
  user_code: string;
  user_id: string | null;
  user_type: string;
  user_familyname: string;
  user_firstname: string;
  user_must_change_password: boolean;
};

// Returns null both when there is no session and when the password reset
// is still pending (Api::V1::MeController enforces that server-side); use
// this only where "fully logged in" is what you actually mean.
export async function getCurrentUser(): Promise<CurrentUser | null> {
  const token = await getSessionToken();
  if (!token) return null;

  const response = await backendFetch("/api/v1/me", { sessionToken: token });
  if (!response.ok) return null;

  const body = (await response.json()) as { user: CurrentUser };
  return body.user;
}
