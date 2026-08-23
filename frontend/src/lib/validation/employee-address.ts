import { z } from "zod";
import { isValidPhoneNumber, PHONE_NUMBER_ERROR_MESSAGE } from "@/lib/validation/phone-number";
import { isValidPostalCode, POSTAL_CODE_ERROR_MESSAGE } from "@/lib/validation/postal-code";

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
    if (tel.at_number && !isValidPhoneNumber(tel.at_number)) {
      ctx.addIssue({
        code: "custom",
        path: ["at_number"],
        message: PHONE_NUMBER_ERROR_MESSAGE,
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
// Spread into lib/validation/employee.ts's updateEmployeeSchema so the
// employee edit screen can carry both the profile and the address fields
// in one form (Issue #32: consolidate the two edit screens into one).
export const addressFields = {
  address_contact_name: z.string().optional().or(z.literal("")),
  address_post: z
    .string()
    .optional()
    .or(z.literal(""))
    .refine((value) => !value || isValidPostalCode(value), { message: POSTAL_CODE_ERROR_MESSAGE }),
  address_residence: z.string().optional().or(z.literal("")),
  address_memo: z.string().optional().or(z.literal("")),
  address_tels: z.array(telSchema),
  address_emails: z.array(emailSchema),
};

export const employeeAddressSchema = z.object(addressFields);

export type EmployeeAddressFormValues = z.infer<typeof employeeAddressSchema>;
