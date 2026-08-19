import { z } from "zod";

export const loginSchema = z.object({
  identifier: z.string().min(1, "ログインIDまたは電話番号を入力してください"),
  password: z.string().min(1, "パスワードを入力してください"),
});

export type LoginFormValues = z.infer<typeof loginSchema>;

// spec section 3.2: minimum 4 characters, intentionally no complexity
// rules (elderly employees are among the users).
export const passwordSchema = z
  .object({
    password: z.string().min(4, "パスワードは4文字以上で入力してください"),
    confirmation: z.string().min(1, "確認のため、もう一度入力してください"),
  })
  .refine((data) => data.password === data.confirmation, {
    message: "パスワードが一致しません",
    path: ["confirmation"],
  });

export type PasswordFormValues = z.infer<typeof passwordSchema>;
