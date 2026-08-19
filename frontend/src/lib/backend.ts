// Server-only helper for calling the Rails API through the internal
// shared-secret gate (Api::V1::BaseController#authenticate_internal_request!).
// Never import this from a Client Component: INTERNAL_API_SECRET must stay
// on the server.
const BACKEND_INTERNAL_URL = process.env.BACKEND_INTERNAL_URL ?? "http://backend:3000";
const INTERNAL_API_SECRET = process.env.INTERNAL_API_SECRET ?? "";

type BackendFetchInit = Omit<RequestInit, "headers"> & {
  headers?: Record<string, string>;
  sessionToken?: string;
};

export function backendFetch(path: string, init: BackendFetchInit = {}) {
  const { sessionToken, headers, ...rest } = init;

  return fetch(`${BACKEND_INTERNAL_URL}${path}`, {
    ...rest,
    headers: {
      "Content-Type": "application/json",
      "X-Internal-Api-Secret": INTERNAL_API_SECRET,
      ...(sessionToken ? { Authorization: `Bearer ${sessionToken}` } : {}),
      ...headers,
    },
    cache: "no-store",
  });
}
