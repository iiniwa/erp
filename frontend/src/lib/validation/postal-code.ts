// Issue #32: displayed/entered as XXX-XXXX, stored (and returned by the
// API) as a hyphen-free 7-digit string — see backend Address#address_post.
const DISPLAY_FORMAT = /^\d{3}-\d{4}$/;

export function isValidPostalCode(value: string): boolean {
  return DISPLAY_FORMAT.test(value);
}

export const POSTAL_CODE_ERROR_MESSAGE =
  "郵便番号はXXX-XXXXの形式で入力してください（例: 100-0001）。";

export function normalizePostalCodeForSubmit(value: string): string {
  return value.replace(/-/g, "");
}

export function formatPostalCodeForDisplay(value: string | null | undefined): string {
  if (!value) return "";
  return value.length === 7 ? `${value.slice(0, 3)}-${value.slice(3)}` : value;
}
