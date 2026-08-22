"use client";

import { useRouter } from "next/navigation";
import { useFieldArray, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  employeeAddressSchema,
  type EmployeeAddressFormValues,
} from "@/lib/validation/employee-address";
import type { EmployeeAddress } from "@/lib/api/employee-address";
import { TelFieldRow, EmailFieldRow } from "@/features/addresses/TelEmailFields";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";

function toDefaultTel(tel: EmployeeAddress["address_tels"][number]) {
  return {
    id: tel.at_id,
    at_number: tel.at_number,
    at_label_type:
      tel.at_label_type as EmployeeAddressFormValues["address_tels"][number]["at_label_type"],
    at_label_free: tel.at_label_free ?? "",
    at_sort: tel.at_sort,
    is_emergency: tel.is_emergency,
  };
}

function toDefaultEmail(email: EmployeeAddress["address_emails"][number]) {
  return {
    id: email.ae_id,
    ae_email: email.ae_email,
    ae_label: email.ae_label ?? "",
    ae_sort: email.ae_sort,
  };
}

export default function EmployeeAddressForm({
  userCode,
  address,
}: {
  userCode: string;
  address: EmployeeAddress;
}) {
  const router = useRouter();
  const { showToast } = useToast();
  const {
    register,
    control,
    handleSubmit,
    getValues,
    formState: { errors, isSubmitting },
  } = useForm<EmployeeAddressFormValues>({
    resolver: zodResolver(employeeAddressSchema),
    defaultValues: {
      address_contact_name: address.address_contact_name ?? "",
      address_post: address.address_post ?? "",
      address_residence: address.address_residence ?? "",
      address_memo: address.address_memo ?? "",
      address_tels: address.address_tels.map(toDefaultTel),
      address_emails: address.address_emails.map(toDefaultEmail),
    },
  });

  const telArray = useFieldArray({ control, name: "address_tels" });
  const emailArray = useFieldArray({ control, name: "address_emails" });

  function removeTel(index: number) {
    const current = getValues(`address_tels.${index}`);
    if (current.id) {
      telArray.update(index, { ...current, _destroy: true });
    } else {
      telArray.remove(index);
    }
  }

  function removeEmail(index: number) {
    const current = getValues(`address_emails.${index}`);
    if (current.id) {
      emailArray.update(index, { ...current, _destroy: true });
    } else {
      emailArray.remove(index);
    }
  }

  function nextSort(count: number) {
    return count + 1;
  }

  async function onSubmit(values: EmployeeAddressFormValues) {
    const payload = {
      address_contact_name: values.address_contact_name || null,
      address_post: values.address_post || null,
      address_residence: values.address_residence || null,
      address_memo: values.address_memo || null,
      address_tels_attributes: values.address_tels,
      address_emails_attributes: values.address_emails,
    };

    try {
      const response = await fetch(`/api/employees/${encodeURIComponent(userCode)}/address`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "保存に失敗しました。", "error");
        return;
      }

      showToast("アドレス帳情報を更新しました。");
      router.push(`/employees/${userCode}`);
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <Card className="max-w-2xl">
      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-6">
        <Input
          id="address_contact_name"
          label="担当者名（任意）"
          error={errors.address_contact_name?.message}
          {...register("address_contact_name")}
        />
        <Input
          id="address_post"
          label="郵便番号（任意）"
          error={errors.address_post?.message}
          {...register("address_post")}
        />
        <Input
          id="address_residence"
          label="住所（任意）"
          error={errors.address_residence?.message}
          {...register("address_residence")}
        />
        <div>
          <label
            htmlFor="address_memo"
            className="mb-1 block text-sm font-medium text-brand-gray-700"
          >
            備考（任意）
          </label>
          <textarea
            id="address_memo"
            rows={3}
            className="w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            {...register("address_memo")}
          />
        </div>

        <div>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="font-medium text-brand-gray-900">電話番号</h2>
            <Button
              type="button"
              variant="secondary"
              onClick={() =>
                telArray.append({
                  at_number: "",
                  at_label_type: "mobile",
                  at_label_free: "",
                  at_sort: nextSort(telArray.fields.length),
                  is_emergency: false,
                })
              }
            >
              追加
            </Button>
          </div>
          <p className="mb-2 text-sm text-brand-gray-500">
            並び順1番の電話番号は携帯である必要があります。
          </p>
          <div className="flex flex-col gap-3">
            {telArray.fields.map((field, index) => (
              <TelFieldRow
                key={field.id}
                control={control}
                register={register}
                errors={errors}
                index={index}
                onRemove={removeTel}
              />
            ))}
          </div>
        </div>

        <div>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="font-medium text-brand-gray-900">メールアドレス</h2>
            <Button
              type="button"
              variant="secondary"
              onClick={() =>
                emailArray.append({
                  ae_email: "",
                  ae_label: "",
                  ae_sort: nextSort(emailArray.fields.length),
                })
              }
            >
              追加
            </Button>
          </div>
          <div className="flex flex-col gap-3">
            {emailArray.fields.map((field, index) => (
              <EmailFieldRow
                key={field.id}
                control={control}
                register={register}
                errors={errors}
                index={index}
                onRemove={removeEmail}
              />
            ))}
          </div>
        </div>

        <Button type="submit" disabled={isSubmitting} className="mt-2">
          {isSubmitting ? "保存中..." : "保存"}
        </Button>
      </form>
    </Card>
  );
}
