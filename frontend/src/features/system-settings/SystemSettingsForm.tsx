"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  bankAccountTypeOptions,
  systemSettingSchema,
  FILE_FIELDS,
  FILE_FIELD_LABELS,
  type SystemSettingFormValues,
} from "@/lib/validation/system-setting";
import type { SystemSetting, SystemSettingFile } from "@/lib/api/system-settings";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";

function toDefaultValues(setting: SystemSetting): SystemSettingFormValues {
  return {
    system_name: setting.system_name ?? "",
    company_name: setting.company_name ?? "",
    company_post: setting.company_post ?? "",
    company_address: setting.company_address ?? "",
    company_tel: setting.company_tel ?? "",
    company_email: setting.company_email ?? "",
    company_invoice_number: setting.company_invoice_number ?? "",
    company_corporate_number: setting.company_corporate_number ?? "",
    representative_position: setting.representative_position ?? "",
    representative_name: setting.representative_name ?? "",
    bank_name: setting.bank_name ?? "",
    bank_branch_name: setting.bank_branch_name ?? "",
    bank_account_type:
      (setting.bank_account_type as SystemSettingFormValues["bank_account_type"]) ?? "",
    bank_account_number: setting.bank_account_number ?? "",
    bank_account_holder: setting.bank_account_holder ?? "",
    default_tax_rate: setting.default_tax_rate ?? "",
    fiscal_year_end_month: setting.fiscal_year_end_month?.toString() ?? "",
    login_lockout_count: setting.login_lockout_count.toString(),
  };
}

export default function SystemSettingsForm({ setting }: { setting: SystemSetting }) {
  const router = useRouter();
  const { showToast } = useToast();
  const [currentFiles, setCurrentFiles] = useState(setting);
  const [selectedFiles, setSelectedFiles] = useState<Partial<Record<string, File>>>({});
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<SystemSettingFormValues>({
    resolver: zodResolver(systemSettingSchema),
    defaultValues: toDefaultValues(setting),
  });

  async function onSubmit(values: SystemSettingFormValues) {
    const formData = new FormData();
    Object.entries(values).forEach(([key, value]) => {
      if (value) formData.append(key, value);
    });
    FILE_FIELDS.forEach((field) => {
      const file = selectedFiles[field];
      if (file) formData.append(field, file);
    });

    try {
      const response = await fetch("/api/system-setting", { method: "PATCH", body: formData });
      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "更新に失敗しました。", "error");
        return;
      }

      showToast("設定を更新しました。");
      setCurrentFiles(body.system_setting);
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <Card className="max-w-3xl">
      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-8">
        <section>
          <h2 className="mb-3 font-medium text-brand-gray-900">システム</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input id="system_name" label="システム名称" {...register("system_name")} />
            <Input
              id="login_lockout_count"
              label="ログインロックアウトまでの失敗回数"
              type="number"
              min={1}
              error={errors.login_lockout_count?.message}
              {...register("login_lockout_count")}
            />
          </div>
        </section>

        <section>
          <h2 className="mb-3 font-medium text-brand-gray-900">自社情報</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input id="company_name" label="会社名" {...register("company_name")} />
            <Input id="company_post" label="郵便番号" {...register("company_post")} />
            <Input id="company_address" label="所在地" {...register("company_address")} />
            <Input id="company_tel" label="電話番号" {...register("company_tel")} />
            <Input
              id="company_email"
              label="メールアドレス"
              error={errors.company_email?.message}
              {...register("company_email")}
            />
            <Input
              id="company_invoice_number"
              label="インボイス番号"
              {...register("company_invoice_number")}
            />
            <Input
              id="company_corporate_number"
              label="法人番号"
              {...register("company_corporate_number")}
            />
            <Input
              id="representative_position"
              label="代表者役職"
              {...register("representative_position")}
            />
            <Input id="representative_name" label="代表者名" {...register("representative_name")} />
          </div>
        </section>

        <section>
          <h2 className="mb-3 font-medium text-brand-gray-900">振込先口座</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input id="bank_name" label="銀行名" {...register("bank_name")} />
            <Input id="bank_branch_name" label="支店名" {...register("bank_branch_name")} />
            <div>
              <label
                htmlFor="bank_account_type"
                className="mb-1 block text-sm font-medium text-brand-gray-700"
              >
                口座種別
              </label>
              <select
                id="bank_account_type"
                className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
                {...register("bank_account_type")}
              >
                <option value="">未設定</option>
                {bankAccountTypeOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
            <Input id="bank_account_number" label="口座番号" {...register("bank_account_number")} />
            <Input
              id="bank_account_holder"
              label="口座名義（カナ）"
              {...register("bank_account_holder")}
            />
          </div>
        </section>

        <section>
          <h2 className="mb-3 font-medium text-brand-gray-900">税・決算</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input
              id="default_tax_rate"
              label="デフォルト消費税率（%）"
              type="number"
              step="0.01"
              {...register("default_tax_rate")}
            />
            <Input
              id="fiscal_year_end_month"
              label="決算月（1〜12）"
              type="number"
              min={1}
              max={12}
              {...register("fiscal_year_end_month")}
            />
          </div>
        </section>

        <section>
          <h2 className="mb-3 font-medium text-brand-gray-900">ロゴ・印影</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {FILE_FIELDS.map((field) => {
              const currentFile = currentFiles[field as keyof SystemSetting] as SystemSettingFile;
              return (
                <div key={field}>
                  <label
                    htmlFor={field}
                    className="mb-1 block text-sm font-medium text-brand-gray-700"
                  >
                    {FILE_FIELD_LABELS[field]}
                  </label>
                  {currentFile && (
                    <p className="mb-1 text-sm text-brand-gray-500">
                      現在のファイル:{" "}
                      <a
                        href={currentFile.url}
                        target="_blank"
                        rel="noreferrer"
                        className="text-brand-green-700 hover:underline"
                      >
                        {currentFile.file_name}
                      </a>
                    </p>
                  )}
                  <input
                    id={field}
                    type="file"
                    accept="image/*"
                    onChange={(event) => {
                      const file = event.target.files?.[0];
                      setSelectedFiles((prev) => ({ ...prev, [field]: file }));
                    }}
                    className="block w-full text-sm text-brand-gray-700 file:mr-3 file:min-h-11 file:rounded-md file:border-0 file:bg-brand-gray-100 file:px-3 file:py-2 file:text-brand-gray-700 hover:file:bg-brand-gray-200"
                  />
                </div>
              );
            })}
          </div>
        </section>

        <Button type="submit" disabled={isSubmitting} className="mt-2">
          {isSubmitting ? "保存中..." : "保存"}
        </Button>
      </form>
    </Card>
  );
}
