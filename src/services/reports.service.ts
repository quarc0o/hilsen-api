import { type SupabaseClient } from "@supabase/supabase-js";

export async function createCardReport(
  supabase: SupabaseClient,
  params: { sendId: string; reason: string; reporterId?: string | null },
) {
  const { error: sendError, count } = await supabase
    .from("card_sends")
    .select("id", { count: "exact", head: true })
    .eq("id", params.sendId);
  if (sendError) throw sendError;
  if (!count) return { ok: false as const, error: "send_not_found" };

  const { data, error } = await supabase
    .from("card_reports")
    .insert({
      card_send_id: params.sendId,
      reporter_id: params.reporterId ?? null,
      reason: params.reason,
    })
    .select("id")
    .single();
  if (error) throw error;

  return { ok: true as const, id: data.id as string };
}
