// Katakana -> hiragana normalization for the address book search (spec
// section 6): address_ruby is stored in hiragana only, but the search box
// should still match when the user types katakana. Converting both the
// query and every searched field through this before comparing makes the
// two kana scripts equivalent without needing a second stored column.
export function toHiragana(value: string): string {
  // NFKC first so half-width katakana (e.g. "ｶﾀｶﾅ") normalizes to
  // full-width before the katakana->hiragana conversion below runs.
  return value
    .normalize("NFKC")
    .replace(/[ァ-ヶ]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0x60));
}

export function normalizeForSearch(value: string): string {
  return toHiragana(value).toLowerCase();
}

// Issue #33: あ・か・さ・た・な・は・ま・や・ら・わ index-jump rows for
// the address book list. Dakuten/handakuten variants (が/ぱ etc.) and
// small kana (っ/ゃ etc.) are grouped under their plain-kana row, matching
// how these index bars work in contact-list UIs generally.
export const GOJUON_ROWS = [
  { label: "あ", chars: "あいうえおぁぃぅぇぉ" },
  { label: "か", chars: "かきくけこがぎぐげご" },
  { label: "さ", chars: "さしすせそざじずぜぞ" },
  { label: "た", chars: "たちつてとだぢづでどっ" },
  { label: "な", chars: "なにぬねの" },
  { label: "は", chars: "はひふへほばびぶべぼぱぴぷぺぽ" },
  { label: "ま", chars: "まみむめも" },
  { label: "や", chars: "やゆよゃゅょ" },
  { label: "ら", chars: "らりるれろ" },
  { label: "わ", chars: "わをんゎ" },
] as const;

// The row a given ふりがな falls under for the index-jump bar, or null
// for anything outside the basic kana set (shouldn't normally happen —
// address_ruby is required and validated as hiragana on input).
export function gojuonRowLabel(ruby: string): string | null {
  const first = toHiragana(ruby).trim().charAt(0);
  return GOJUON_ROWS.find((row) => row.chars.includes(first))?.label ?? null;
}

// あいうえお順: compares two ふりがな values via hiragana-normalized,
// locale-aware collation (plain codepoint order already tracks gojuon
// order closely, but "ja" collation handles edge cases correctly).
export function compareByRuby(a: string, b: string): number {
  return toHiragana(a).localeCompare(toHiragana(b), "ja");
}
