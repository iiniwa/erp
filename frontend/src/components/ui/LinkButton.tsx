import Link from "next/link";
import type { ComponentProps } from "react";
import { BUTTON_VARIANT_CLASSES, type ButtonVariant } from "@/components/ui/Button";

type LinkButtonProps = ComponentProps<typeof Link> & {
  variant?: ButtonVariant;
};

// A Button-styled Link, for navigation actions (a real <button> can't be
// nested inside the <a> that Link renders).
export default function LinkButton({
  variant = "primary",
  className = "",
  ...props
}: LinkButtonProps) {
  return (
    <Link
      className={`inline-flex min-h-11 min-w-11 items-center justify-center rounded-md px-4 py-2 font-medium transition-colors ${BUTTON_VARIANT_CLASSES[variant]} ${className}`}
      {...props}
    />
  );
}
