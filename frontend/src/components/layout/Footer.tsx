export default function Footer() {
  return (
    <footer className="border-t border-brand-gray-200 bg-white py-4 text-center text-sm text-brand-gray-500">
      © {new Date().getFullYear()} ERPシステム
    </footer>
  );
}
