// Mirrors backend/app/services/phone_number_format.rb (spec section 445:
// validation rules must stay consistent between the zod schema and the
// backend check). Not an exhaustive Japanese phone number database — area
// code lists run into the hundreds of entries — but a pragmatic ruleset
// covering the shapes that matter here:
//   - mobile / IP phone: 3-4-4 = 11 digits (090/080/070/050-XXXX-XXXX)
//   - freedial / navi-dial: 4-3-3 = 10 digits (0120/0800/0570-XXX-XXX)
//   - landline: variable area-code length, but always 10 digits total
// International numbers (leading "+") are checked more loosely, since
// per-country grouping rules are out of scope here.
const MOBILE = /^0[5789]0-\d{4}-\d{4}$/;
const FREEDIAL = /^0(120|800|570)-\d{3}-\d{3}$/;
const LANDLINE = /^0\d{1,4}-\d{1,4}-\d{4}$/;
// Deliberately not grouping-strict: unlike Japan's domestic numbers,
// requiring specific hyphen positions here would reject perfectly valid
// numbers written without hyphens at all (e.g. "+14155552671"), since
// per-country grouping conventions vary and are out of scope. Only "+"
// followed by digits/hyphens, with a digit-count check, matters.
const INTERNATIONAL = /^\+[\d-]+$/;

export function isValidPhoneNumber(value: string): boolean {
  if (!value) return false;
  if (value.includes("(") || value.includes(")")) return false;

  if (value.startsWith("+")) {
    if (!INTERNATIONAL.test(value)) return false;
    const digitCount = value.replace(/[^0-9]/g, "").length;
    return digitCount >= 8 && digitCount <= 15;
  }

  if (MOBILE.test(value) || FREEDIAL.test(value)) return true;

  return LANDLINE.test(value) && value.replace(/-/g, "").length === 10;
}

export const PHONE_NUMBER_ERROR_MESSAGE =
  "電話番号の形式が正しくありません（例: 090-1234-5678）。区切りにはハイフンのみ使用できます。";
