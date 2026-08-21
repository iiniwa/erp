"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  useFieldArray,
  useForm,
  useWatch,
  type Control,
  type FieldErrors,
  type UseFormRegister,
} from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { addressSchema, telLabelOptions, type AddressFormValues } from "@/lib/validation/address";
import type { AddressBookEntry, AddressCategory } from "@/lib/api/addresses";
import type { Employee } from "@/lib/api/employees";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";

type AddressFormProps = {
  mode: "create" | "edit";
  address?: AddressBookEntry;
  categories: AddressCategory[];
  employees: Employee[];
};

// useWatch (a real hook call) instead of destructuring watch() from
// useForm and invoking it inline inside a .map(): the latter trips
// react-hooks/incompatible-library (its return value can't be memoized
// safely by the React Compiler).
function TelFieldRow({
  control,
  register,
  errors,
  index,
  onRemove,
}: {
  control: Control<AddressFormValues>;
  register: UseFormRegister<AddressFormValues>;
  errors: FieldErrors<AddressFormValues>;
  index: number;
  onRemove: (index: number) => void;
}) {
  const destroyed = useWatch({ control, name: `address_tels.${index}._destroy` });
  const labelType = useWatch({ control, name: `address_tels.${index}.at_label_type` });

  if (destroyed) return null;

  return (
    <div className="flex flex-col gap-2 rounded-md border border-brand-gray-200 p-3 sm:flex-row sm:items-start">
      <div className="flex-1">
        <Input
          id={`address_tels.${index}.at_number`}
          label="電話番号"
          error={errors.address_tels?.[index]?.at_number?.message}
          {...register(`address_tels.${index}.at_number`)}
        />
      </div>
      <div className="flex-1">
        <label
          htmlFor={`address_tels.${index}.at_label_type`}
          className="mb-1 block text-sm font-medium text-brand-gray-700"
        >
          ラベル
        </label>
        <select
          id={`address_tels.${index}.at_label_type`}
          className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
          {...register(`address_tels.${index}.at_label_type`)}
        >
          {telLabelOptions.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>
      {labelType === "free" && (
        <div className="flex-1">
          <Input
            id={`address_tels.${index}.at_label_free`}
            label="ラベル名"
            error={errors.address_tels?.[index]?.at_label_free?.message}
            {...register(`address_tels.${index}.at_label_free`)}
          />
        </div>
      )}
      <Button
        type="button"
        variant="danger"
        className="mt-6 sm:mt-6"
        onClick={() => onRemove(index)}
      >
        削除
      </Button>
    </div>
  );
}

function EmailFieldRow({
  control,
  register,
  errors,
  index,
  onRemove,
}: {
  control: Control<AddressFormValues>;
  register: UseFormRegister<AddressFormValues>;
  errors: FieldErrors<AddressFormValues>;
  index: number;
  onRemove: (index: number) => void;
}) {
  const destroyed = useWatch({ control, name: `address_emails.${index}._destroy` });

  if (destroyed) return null;

  return (
    <div className="flex flex-col gap-2 rounded-md border border-brand-gray-200 p-3 sm:flex-row sm:items-start">
      <div className="flex-1">
        <Input
          id={`address_emails.${index}.ae_email`}
          label="メールアドレス"
          error={errors.address_emails?.[index]?.ae_email?.message}
          {...register(`address_emails.${index}.ae_email`)}
        />
      </div>
      <div className="flex-1">
        <Input
          id={`address_emails.${index}.ae_label`}
          label="ラベル（任意）"
          {...register(`address_emails.${index}.ae_label`)}
        />
      </div>
      <Button
        type="button"
        variant="danger"
        className="mt-6 sm:mt-6"
        onClick={() => onRemove(index)}
      >
        削除
      </Button>
    </div>
  );
}

function toDefaultTel(tel: AddressBookEntry["address_tels"][number]) {
  return {
    id: tel.at_id,
    at_number: tel.at_number,
    at_label_type: tel.at_label_type as AddressFormValues["address_tels"][number]["at_label_type"],
    at_label_free: tel.at_label_free ?? "",
    at_sort: tel.at_sort,
  };
}

function toDefaultEmail(email: AddressBookEntry["address_emails"][number]) {
  return {
    id: email.ae_id,
    ae_email: email.ae_email,
    ae_label: email.ae_label ?? "",
    ae_sort: email.ae_sort,
  };
}

export default function AddressForm({ mode, address, categories, employees }: AddressFormProps) {
  const router = useRouter();
  const { showToast } = useToast();
  const [categoryList, setCategoryList] = useState(categories);
  const [newCategoryName, setNewCategoryName] = useState("");
  const [addingCategory, setAddingCategory] = useState(false);

  const {
    register,
    control,
    handleSubmit,
    setValue,
    getValues,
    formState: { errors, isSubmitting },
  } = useForm<AddressFormValues>({
    resolver: zodResolver(addressSchema),
    defaultValues: {
      address_category_id: address?.address_category_id ?? categories[0]?.ac_id,
      address_name: address?.address_name ?? "",
      address_ruby: address?.address_ruby ?? "",
      address_user_code: address?.address_user_code ?? "",
      address_contact_name: address?.address_contact_name ?? "",
      address_post: address?.address_post ?? "",
      address_residence: address?.address_residence ?? "",
      address_memo: address?.address_memo ?? "",
      address_tels: address?.address_tels.map(toDefaultTel) ?? [],
      address_emails: address?.address_emails.map(toDefaultEmail) ?? [],
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

  async function handleAddCategory() {
    if (!newCategoryName.trim()) return;
    setAddingCategory(true);
    try {
      const response = await fetch("/api/address-categories", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ac_name: newCategoryName.trim(), ac_sort: categoryList.length + 1 }),
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "カテゴリの追加に失敗しました。", "error");
        return;
      }
      setCategoryList((prev) => [...prev, body.address_category]);
      setValue("address_category_id", body.address_category.ac_id);
      setNewCategoryName("");
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    } finally {
      setAddingCategory(false);
    }
  }

  async function onSubmit(values: AddressFormValues) {
    const payload = {
      address_category_id: values.address_category_id,
      address_name: values.address_name,
      address_ruby: values.address_ruby,
      address_user_code: values.address_user_code || null,
      address_contact_name: values.address_contact_name || null,
      address_post: values.address_post || null,
      address_residence: values.address_residence || null,
      address_memo: values.address_memo || null,
      address_tels_attributes: values.address_tels,
      address_emails_attributes: values.address_emails,
    };

    try {
      const url = mode === "create" ? "/api/addresses" : `/api/addresses/${address?.address_id}`;
      const response = await fetch(url, {
        method: mode === "create" ? "POST" : "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        showToast(body.errors?.join("、") ?? "保存に失敗しました。", "error");
        return;
      }

      showToast(mode === "create" ? "アドレス帳に登録しました。" : "更新しました。");
      router.push(`/addresses/${body.address.address_id}`);
      router.refresh();
    } catch {
      showToast("通信に失敗しました。ネットワーク接続を確認してください。", "error");
    }
  }

  return (
    <Card className="max-w-2xl">
      <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            id="address_name"
            label="名称"
            error={errors.address_name?.message}
            {...register("address_name")}
          />
          <Input
            id="address_ruby"
            label="ふりがな（ひらがな）"
            error={errors.address_ruby?.message}
            {...register("address_ruby")}
          />
        </div>

        <div>
          <label
            htmlFor="address_category_id"
            className="mb-1 block text-sm font-medium text-brand-gray-700"
          >
            カテゴリ
          </label>
          <select
            id="address_category_id"
            className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            {...register("address_category_id", { valueAsNumber: true })}
          >
            {categoryList.map((category) => (
              <option key={category.ac_id} value={category.ac_id}>
                {category.ac_name}
              </option>
            ))}
          </select>
          {errors.address_category_id && (
            <p role="alert" className="mt-1 text-sm text-red-600">
              {errors.address_category_id.message}
            </p>
          )}
          <div className="mt-2 flex gap-2">
            <input
              type="text"
              value={newCategoryName}
              onChange={(event) => setNewCategoryName(event.target.value)}
              placeholder="新しいカテゴリ名"
              className="min-h-11 flex-1 rounded-md border border-brand-gray-300 px-3 py-2 text-sm focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            />
            <Button
              type="button"
              variant="secondary"
              disabled={addingCategory}
              onClick={handleAddCategory}
            >
              追加
            </Button>
          </div>
        </div>

        <div>
          <label
            htmlFor="address_user_code"
            className="mb-1 block text-sm font-medium text-brand-gray-700"
          >
            紐づく従業員（任意）
          </label>
          <select
            id="address_user_code"
            className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            {...register("address_user_code")}
          >
            <option value="">紐づけなし（取引先等）</option>
            {employees.map((employee) => (
              <option key={employee.user_code} value={employee.user_code}>
                {employee.user_familyname} {employee.user_firstname}
              </option>
            ))}
          </select>
        </div>

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
                })
              }
            >
              追加
            </Button>
          </div>
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
