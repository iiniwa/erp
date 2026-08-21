// Katakana -> hiragana normalization for the address book search (spec
// section 6): address_ruby is stored in hiragana only, but the search box
// should still match when the user types katakana. Converting both the
// query and every searched field through this before comparing makes the
// two kana scripts equivalent without needing a second stored column.
export function toHiragana(value: string): string {
  return value.replace(/[ァ-ヶ]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0x60));
}

export function normalizeForSearch(value: string): string {
  return toHiragana(value).toLowerCase();
}
