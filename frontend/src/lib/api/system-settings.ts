import { backendFetch } from "@/lib/backend";
import { getSessionToken } from "@/lib/session";

export type SystemSettingFile = { file_name: string; url: string } | null;

export type SystemSetting = {
  system_name: string | null;
  company_name: string | null;
  company_post: string | null;
  company_address: string | null;
  company_tel: string | null;
  company_fax: string | null;
  company_toll_free: string | null;
  company_email: string | null;
  company_invoice_number: string | null;
  company_corporate_number: string | null;
  representative_position: string | null;
  representative_name: string | null;
  bank_name: string | null;
  bank_branch_name: string | null;
  bank_account_type: string | null;
  bank_account_number: string | null;
  bank_account_holder: string | null;
  default_tax_rate: string | null;
  fiscal_year_end_month: number | null;
  login_lockout_count: number;
  updated_at: string | null;
  updated_by: string | null;
  system_logo_file: SystemSettingFile;
  system_favicon_file: SystemSettingFile;
  corporate_logo_file: SystemSettingFile;
  corporate_logotype_file: SystemSettingFile;
  company_seal_file: SystemSettingFile;
  company_square_seal_file: SystemSettingFile;
};

// Server-side data fetcher for the Server Component page. Only "no
// session" returns null; any other failure (not system_admin, backend
// error) throws, since t.system always has exactly one row so there is no
// legitimate "not found" case here.
export async function fetchSystemSetting(): Promise<SystemSetting | null> {
  const token = await getSessionToken();
  if (!token) return null;

  const response = await backendFetch("/api/v1/system_setting", { sessionToken: token });
  if (!response.ok) {
    throw new Error(`Failed to fetch system setting (status ${response.status})`);
  }

  const body = (await response.json()) as { system_setting: SystemSetting };
  return body.system_setting;
}
