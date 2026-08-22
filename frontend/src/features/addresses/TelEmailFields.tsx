"use client";

import {
  useWatch,
  type Control,
  type FieldErrors,
  type Path,
  type UseFormRegister,
} from "react-hook-form";
import { telLabelOptions } from "@/lib/validation/address";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";

// Shared by AddressForm (business contacts) and EmployeeAddressForm
// (employees' own entries, edited only from Employee Management) — both
// forms carry an `address_tels`/`address_emails` array of this same
// shape, just embedded in otherwise-different form value types. Generic
// over the concrete form type so either can reuse these without a cast.
type TelEmailFormShape = {
  address_tels: {
    at_number: string;
    at_label_type: string;
    at_label_free?: string;
    _destroy?: boolean;
  }[];
  address_emails: { ae_email: string; _destroy?: boolean }[];
};

// useWatch (a real hook call) instead of destructuring watch() from
// useForm and invoking it inline inside a .map(): the latter trips
// react-hooks/incompatible-library (its return value can't be memoized
// safely by the React Compiler).
export function TelFieldRow<T extends TelEmailFormShape>({
  control,
  register,
  errors,
  index,
  onRemove,
}: {
  control: Control<T>;
  register: UseFormRegister<T>;
  errors: FieldErrors<T>;
  index: number;
  onRemove: (index: number) => void;
}) {
  const destroyed = useWatch({ control, name: `address_tels.${index}._destroy` as Path<T> });
  const labelType = useWatch({ control, name: `address_tels.${index}.at_label_type` as Path<T> });

  if (destroyed) return null;

  const telErrors = (errors as FieldErrors<TelEmailFormShape>).address_tels?.[index];

  return (
    <div className="flex flex-col gap-2 rounded-md border border-brand-gray-200 p-3 sm:flex-row sm:items-start">
      <div className="flex-1">
        <Input
          id={`address_tels.${index}.at_number`}
          label="電話番号"
          error={telErrors?.at_number?.message}
          {...register(`address_tels.${index}.at_number` as Path<T>)}
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
          {...register(`address_tels.${index}.at_label_type` as Path<T>)}
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
            error={telErrors?.at_label_free?.message}
            {...register(`address_tels.${index}.at_label_free` as Path<T>)}
          />
        </div>
      )}
      <label className="mt-6 flex min-h-11 items-center gap-2 text-sm text-brand-gray-700">
        <input type="checkbox" {...register(`address_tels.${index}.is_emergency` as Path<T>)} />
        緊急連絡先
      </label>
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

export function EmailFieldRow<T extends TelEmailFormShape>({
  control,
  register,
  errors,
  index,
  onRemove,
}: {
  control: Control<T>;
  register: UseFormRegister<T>;
  errors: FieldErrors<T>;
  index: number;
  onRemove: (index: number) => void;
}) {
  const destroyed = useWatch({ control, name: `address_emails.${index}._destroy` as Path<T> });

  if (destroyed) return null;

  const emailErrors = (errors as FieldErrors<TelEmailFormShape>).address_emails?.[index];

  return (
    <div className="flex flex-col gap-2 rounded-md border border-brand-gray-200 p-3 sm:flex-row sm:items-start">
      <div className="flex-1">
        <Input
          id={`address_emails.${index}.ae_email`}
          label="メールアドレス"
          error={emailErrors?.ae_email?.message}
          {...register(`address_emails.${index}.ae_email` as Path<T>)}
        />
      </div>
      <div className="flex-1">
        <Input
          id={`address_emails.${index}.ae_label`}
          label="ラベル（任意）"
          {...register(`address_emails.${index}.ae_label` as Path<T>)}
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
