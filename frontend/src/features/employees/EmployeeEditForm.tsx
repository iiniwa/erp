"use client";

import { useRouter } from "next/navigation";
import { useFieldArray, useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  updateEmployeeSchema,
  decodeKubun,
  encodeKubun,
  type UpdateEmployeeFormValues,
} from "@/lib/validation/employee";
import { TelFieldRow, EmailFieldRow } from "@/features/addresses/TelEmailFields";
import {
  formatPostalCodeForDisplay,
  normalizePostalCodeForSubmit,
} from "@/lib/validation/postal-code";
import { useToast } from "@/components/ui/ToastProvider";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Card from "@/components/ui/Card";
import type { Employee } from "@/lib/api/employees";
import type { EmployeeAddress } from "@/lib/api/employee-address";
import type { PermissionRole } from "@/lib/api/permissions";

type Props = { employee: Employee; address: EmployeeAddress; permissionRoles: PermissionRole[] };

function toDefaultTel(tel: EmployeeAddress["address_tels"][number]) {
  return {
    id: tel.at_id,
    at_number: tel.at_number,
    at_label_type:
      tel.at_label_type as UpdateEmployeeFormValues["address_tels"][number]["at_label_type"],
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

// Issue #32: the employee's own address book entry (spec section 5.2) can
// only ever be edited from here — this form now covers both the employee
// profile and that address entry, submitted together, rather than the two
// living on separate screens.
export default function EmployeeEditForm({ employee, address, permissionRoles }: Props) {
  const router = useRouter();
  const { showToast } = useToast();
  const isSystemAdmin = employee.user_type === "system_admin";
  // The dropdown only ever offers システム管理者 or a role from the
  // table (see PermissionSettings) — there is no third "一般" bucket to
  // fall back to. If this employee somehow has no role assigned (e.g.
  // their role was since deleted), encodeKubun's "general" sentinel
  // wouldn't match any rendered <option>, and a native <select> would
  // silently default to the first one — so treat that case as unset and
  // force an explicit re-selection instead.
  const encodedKubun = encodeKubun(employee);
  const hasMatchingRole = permissionRoles.some((role) => role.role_id.toString() === encodedKubun);
  const {
    register,
    control,
    handleSubmit,
    getValues,
    formState: { errors, isSubmitting },
  } = useForm<UpdateEmployeeFormValues>({
    resolver: zodResolver(updateEmployeeSchema),
    defaultValues: {
      user_familyname: employee.user_familyname,
      user_firstname: employee.user_firstname,
      user_familyname_ruby: employee.user_familyname_ruby,
      user_firstname_ruby: employee.user_firstname_ruby,
      user_join_date: employee.user_join_date ?? "",
      user_id: employee.user_id ?? "",
      kubun: isSystemAdmin || hasMatchingRole ? encodedKubun : "",
      address_contact_name: address.address_contact_name ?? "",
      address_post: formatPostalCodeForDisplay(address.address_post),
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

  async function onSubmit(values: UpdateEmployeeFormValues) {
    const {
      kubun,
      address_contact_name,
      address_post,
      address_residence,
      address_memo,
      address_tels,
      address_emails,
      ...profileFields
    } = values;

    try {
      // Two separate backend resources (t.users / t.address), so this is
      // two requests — but one form, one submit, one error surface, so it
      // still reads as a single save to the user.
      const [profileResponse, addressResponse] = await Promise.all([
        fetch(`/api/employees/${employee.user_code}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...profileFields, role_id: decodeKubun(kubun).role_id }),
        }),
        fetch(`/api/employees/${encodeURIComponent(employee.user_code)}/address`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            address_contact_name: address_contact_name || null,
            address_post: address_post ? normalizePostalCodeForSubmit(address_post) : null,
            address_residence: address_residence || null,
            address_memo: address_memo || null,
            address_tels_attributes: address_tels,
            address_emails_attributes: address_emails,
          }),
        }),
      ]);

      const [profileBody, addressBody] = await Promise.all([
        profileResponse.json().catch(() => ({})),
        addressResponse.json().catch(() => ({})),
      ]);

      const errorMessages = [...(profileBody.errors ?? []), ...(addressBody.errors ?? [])];
      if (!profileResponse.ok || !addressResponse.ok) {
        showToast(errorMessages.join("、") || "更新に失敗しました。", "error");
        return;
      }

      showToast("更新しました。");
      router.push(`/employees/${employee.user_code}`);
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
            id="user_familyname"
            label="姓"
            error={errors.user_familyname?.message}
            {...register("user_familyname")}
          />
          <Input
            id="user_firstname"
            label="名"
            error={errors.user_firstname?.message}
            {...register("user_firstname")}
          />
          <Input
            id="user_familyname_ruby"
            label="せい（ひらがな）"
            error={errors.user_familyname_ruby?.message}
            {...register("user_familyname_ruby")}
          />
          <Input
            id="user_firstname_ruby"
            label="めい（ひらがな）"
            error={errors.user_firstname_ruby?.message}
            {...register("user_firstname_ruby")}
          />
        </div>
        <Input
          id="user_join_date"
          type="date"
          label="入社日（任意）"
          error={errors.user_join_date?.message}
          {...register("user_join_date")}
        />
        <Input
          id="user_id"
          label="ログインID（任意）"
          error={errors.user_id?.message}
          {...register("user_id")}
        />
        <div>
          <label htmlFor="kubun" className="mb-1 block text-sm font-medium text-brand-gray-700">
            区分
          </label>
          {isSystemAdmin ? (
            <>
              <p className="min-h-11 flex items-center text-brand-gray-700">
                システム管理者（変更できません）
              </p>
              <input type="hidden" {...register("kubun")} />
            </>
          ) : (
            <select
              id="kubun"
              className="min-h-11 w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
              {...register("kubun")}
            >
              {!hasMatchingRole && <option value="">選択してください</option>}
              {permissionRoles.map((role) => (
                <option key={role.role_id} value={role.role_id}>
                  {role.role_name}
                </option>
              ))}
            </select>
          )}
          {errors.kubun && (
            <p role="alert" className="mt-1 text-sm text-red-600">
              {errors.kubun.message}
            </p>
          )}
        </div>

        <hr className="border-brand-gray-200" />

        <h2 className="font-medium text-brand-gray-900">アドレス帳情報</h2>
        <Input
          id="address_contact_name"
          label="担当者名（任意）"
          error={errors.address_contact_name?.message}
          {...register("address_contact_name")}
        />
        <Input
          id="address_post"
          label="郵便番号（任意）"
          placeholder="100-0001"
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
            autoComplete="off"
            className="w-full rounded-md border border-brand-gray-300 px-3 py-2 focus:border-brand-green-500 focus:outline-none focus:ring-1 focus:ring-brand-green-500"
            {...register("address_memo")}
          />
        </div>

        <div>
          <div className="mb-2 flex items-center justify-between">
            <h3 className="font-medium text-brand-gray-900">電話番号</h3>
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
            <h3 className="font-medium text-brand-gray-900">メールアドレス</h3>
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
          {isSubmitting ? "更新中..." : "更新"}
        </Button>
      </form>
    </Card>
  );
}
