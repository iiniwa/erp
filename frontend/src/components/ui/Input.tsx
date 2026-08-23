import { forwardRef, type InputHTMLAttributes } from "react";

type InputProps = InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  error?: string;
};

const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  // Browser autofill/autocomplete is disabled by default across the app
  // (per product requirement — this applies to every input, current and
  // future); pass an explicit autoComplete prop to opt a specific field
  // back in if one is ever needed.
  { label, error, id, className = "", autoComplete = "off", ...props },
  ref,
) {
  return (
    <div>
      <label htmlFor={id} className="mb-1 block text-sm font-medium text-brand-gray-700">
        {label}
      </label>
      <input
        ref={ref}
        id={id}
        autoComplete={autoComplete}
        className={`min-h-11 w-full rounded-md border px-3 py-2 focus:outline-none focus:ring-1 ${
          error
            ? "border-red-400 focus:border-red-500 focus:ring-red-500"
            : "border-brand-gray-300 focus:border-brand-green-500 focus:ring-brand-green-500"
        } ${className}`}
        {...props}
      />
      {error && (
        <p role="alert" className="mt-1 text-sm text-red-600">
          {error}
        </p>
      )}
    </div>
  );
});

export default Input;
