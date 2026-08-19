import type { ReactNode } from "react";

type CardProps = {
  children: ReactNode;
  className?: string;
};

export default function Card({ children, className = "" }: CardProps) {
  return (
    <div className={`rounded-lg border border-brand-gray-200 bg-white p-8 shadow-sm ${className}`}>
      {children}
    </div>
  );
}
