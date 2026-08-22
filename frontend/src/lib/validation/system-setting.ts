import { z } from "zod";

export const BANK_ACCOUNT_TYPE_VALUES = ["ordinary", "checking"] as const;

export const bankAccountTypeOptions: {
  value: (typeof BANK_ACCOUNT_TYPE_VALUES)[number];
  label: string;
}[] = [
  { value: "ordinary", label: "普通" },
  { value: "checking", label: "当座" },
];

const optionalString = z.string().optional().or(z.literal(""));

export const systemSettingSchema = z.object({
  system_name: optionalString,
  company_name: optionalString,
  company_post: optionalString,
  company_address: optionalString,
  company_tel: optionalString,
  company_fax: optionalString,
  company_toll_free: optionalString,
  company_email: z
    .union([z.literal(""), z.email("正しいメールアドレスを入力してください")])
    .optional(),
  company_invoice_number: optionalString,
  company_corporate_number: optionalString,
  representative_position: optionalString,
  representative_name: optionalString,
  bank_name: optionalString,
  bank_branch_name: optionalString,
  bank_account_type: z.union([z.literal(""), z.enum(BANK_ACCOUNT_TYPE_VALUES)]).optional(),
  bank_account_number: optionalString,
  bank_account_holder: optionalString,
  default_tax_rate: optionalString,
  fiscal_year_end_month: optionalString,
  login_lockout_count: z.string().min(1, "ロックアウトまでの失敗回数を入力してください"),
});

export type SystemSettingFormValues = z.infer<typeof systemSettingSchema>;

export const FILE_FIELD_LABELS: Record<string, string> = {
  system_logo_file: "システムロゴ",
  system_favicon_file: "システムファビコン",
  corporate_logo_file: "コーポレートロゴ",
  corporate_logotype_file: "コーポレートロゴタイプ",
  company_seal_file: "代表者印",
  company_square_seal_file: "角印",
};

export const FILE_FIELDS = Object.keys(FILE_FIELD_LABELS) as (keyof typeof FILE_FIELD_LABELS)[];

// Matches FileStorageService::ALLOWED_CONTENT_TYPES on the backend, which
// is the real enforcement point; this only gives the user an earlier,
// friendlier rejection than a round-trip 422. Deliberately excludes
// image/svg+xml: an SVG is XML that can embed <script>, and the file gets
// served back with Content-Disposition: inline.
export const ALLOWED_IMAGE_TYPES = ["image/png", "image/jpeg", "image/gif", "image/webp"];
