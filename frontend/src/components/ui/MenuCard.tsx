import Link from "next/link";

type MenuCardProps = {
  href: string;
  title: string;
  description: string;
};

export default function MenuCard({ href, title, description }: MenuCardProps) {
  return (
    <Link
      href={href}
      className="flex min-h-11 flex-col gap-2 rounded-lg border border-brand-gray-200 bg-white p-6 shadow-sm transition-colors hover:border-brand-green-400 hover:bg-brand-green-50"
    >
      <span className="text-lg font-semibold text-brand-gray-900">{title}</span>
      <span className="text-sm text-brand-gray-600">{description}</span>
    </Link>
  );
}
