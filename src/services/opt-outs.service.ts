import { type SupabaseClient } from "@supabase/supabase-js";

function normalizePhone(phone: string): string {
  return phone.replace(/^\+/, "");
}

export async function addOptOut(
  supabase: SupabaseClient,
  phone: string,
  source: "form" | "email" | "api",
) {
  const phone_number = normalizePhone(phone);
  const { error } = await supabase
    .from("sms_opt_outs")
    .upsert({ phone_number, source }, { onConflict: "phone_number", ignoreDuplicates: true });
  if (error) throw error;
  return { phone_number };
}

export async function getOptedOutPhones(
  supabase: SupabaseClient,
  phones: string[],
): Promise<Set<string>> {
  if (phones.length === 0) return new Set();
  const normalized = phones.map(normalizePhone);
  const { data, error } = await supabase
    .from("sms_opt_outs")
    .select("phone_number")
    .in("phone_number", normalized);
  if (error) throw error;
  return new Set((data ?? []).map((r) => r.phone_number as string));
}
