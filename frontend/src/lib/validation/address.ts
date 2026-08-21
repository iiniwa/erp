import { z } from "zod";

export const AT_LABEL_TYPE_VALUES = ["mobile", "main", "fax", "home", "emergency", "free"] as const;

export const telLabelOptions: { value: (typeof AT_LABEL_TYPE_VALUES)[number]; label: string }[] = [
  { value: "mobile", label: "携帯" },
  { value: "main", label: "代表" },
  { value: "fax", label: "FAX" },
  { value: "home", label: "自宅" },
  { value: "emergency", label: "緊急連絡先" },
  { value: "free", label: "自由入力" },
];

export const telLabelText: Record<string, string> = {
  mobile: "携帯",
  main: "代表",
  fax: "FAX",
  home: "自宅",
  emergency: "緊急連絡先",
  free: "自由入力",
};

const telSchema = z
  .object({
    id: z.number().optional(),
    at_number: z.string().min(1, "電話番号を入力してください"),
    at_label_type: z.enum(AT_LABEL_TYPE_VALUES),
    at_label_free: z.string().optional().or(z.literal("")),
    at_sort: z.number(),
    _destroy: z.boolean().optional(),
  })
  .superRefine((tel, ctx) => {
    if (tel.at_label_type === "free" && !tel.at_label_free) {
      ctx.addIssue({
        code: "custom",
        path: ["at_label_free"],
        message: "自由入力ラベルを入力してください",
      });
    }
  });

const emailSchema = z.object({
  id: z.number().optional(),
  ae_email: z.email("正しいメールアドレスを入力してください"),
  ae_label: z.string().optional().or(z.literal("")),
  ae_sort: z.number(),
  _destroy: z.boolean().optional(),
});

export const addressSchema = z.object({
  address_category_id: z.number({ error: "カテゴリを選択してください" }).positive(),
  address_name: z.string().min(1, "名称を入力してください"),
  address_ruby: z.string().min(1, "ふりがな（ひらがな）を入力してください"),
  address_user_code: z.string().optional().or(z.literal("")),
  address_contact_name: z.string().optional().or(z.literal("")),
  address_post: z.string().optional().or(z.literal("")),
  address_residence: z.string().optional().or(z.literal("")),
  address_memo: z.string().optional().or(z.literal("")),
  address_tels: z.array(telSchema),
  address_emails: z.array(emailSchema),
});

export type AddressFormValues = z.infer<typeof addressSchema>;
