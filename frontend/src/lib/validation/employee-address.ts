import { z } from "zod";

const telSchema = z
  .object({
    id: z.number().optional(),
    at_number: z.string().min(1, "電話番号を入力してください"),
    at_label_type: z.enum(["mobile", "main", "fax", "home", "free"] as const),
    at_label_free: z.string().optional().or(z.literal("")),
    at_sort: z.number(),
    is_emergency: z.boolean().optional(),
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

// No address_category_id: employee addresses are always filed under the
// fixed "社内" category server-side (see EmployeeAddressesController).
export const employeeAddressSchema = z.object({
  address_contact_name: z.string().optional().or(z.literal("")),
  address_post: z.string().optional().or(z.literal("")),
  address_residence: z.string().optional().or(z.literal("")),
  address_memo: z.string().optional().or(z.literal("")),
  address_tels: z.array(telSchema),
  address_emails: z.array(emailSchema),
});

export type EmployeeAddressFormValues = z.infer<typeof employeeAddressSchema>;
