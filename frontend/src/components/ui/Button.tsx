import { forwardRef, type ButtonHTMLAttributes } from "react";

export type ButtonVariant = "primary" | "secondary" | "danger";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
};

// min-h-11/min-w-11 (44px at the app's 16px Tailwind rem scale, larger
// still at the 18px root font-size set in globals.css) satisfies the
// spec's minimum tap-target size for elderly users. Exported so
// LinkButton can render the same look for navigation "buttons" (an <a>
// styled like a button, since a real <button> can't nest inside a Link).
export const BUTTON_VARIANT_CLASSES: Record<ButtonVariant, string> = {
  primary: "bg-brand-green-600 text-white hover:bg-brand-green-700",
  secondary: "border border-brand-gray-300 text-brand-gray-700 hover:bg-brand-gray-100",
  danger: "bg-red-600 text-white hover:bg-red-700",
};

const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", className = "", ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      className={`inline-flex min-h-11 min-w-11 items-center justify-center rounded-md px-4 py-2 font-medium transition-colors disabled:opacity-50 ${BUTTON_VARIANT_CLASSES[variant]} ${className}`}
      {...props}
    />
  );
});

export default Button;
