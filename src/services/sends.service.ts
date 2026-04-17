import { type SupabaseClient } from "@supabase/supabase-js";
import { sendCardSms, type TwilioConfig } from "./notifications.service.js";

export interface SendsWorkerConfig {
  twilio: TwilioConfig;
  appBaseUrl: string;
}

export async function sendCard(
  supabase: SupabaseClient,
  senderId: string,
  cardId: string,
  options: { recipientPhones: string[]; scheduledAt?: string },
) {
  const { recipientPhones, scheduledAt } = options;

  const sendGroupId =
    recipientPhones.length > 1 ? crypto.randomUUID() : null;

  const rows = recipientPhones.map((phone) => ({
    card_id: cardId,
    sender_id: senderId,
    recipient_phone: phone,
    send_group_id: sendGroupId,
    status: "scheduled",
    scheduled_at: scheduledAt ?? new Date().toISOString(),
    sent_at: null,
  }));

  const { data: sends, error } = await supabase
    .from("card_sends")
    .insert(rows)
    .select();

  if (error) throw error;

  return sends;
}

export async function getMySends(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("card_sends")
    .select("*")
    .eq("sender_id", userId)
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}

export async function getSendById(supabase: SupabaseClient, sendId: string) {
  const { data, error } = await supabase.from("card_sends").select("*").eq("id", sendId).single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function updateScheduledSend(
  supabase: SupabaseClient,
  sendId: string,
  senderId: string,
  updates: { scheduledAt?: string; recipientPhone?: string },
) {
  const send = await getSendById(supabase, sendId);
  if (!send) return { error: "not_found" as const };
  if (send.sender_id !== senderId) return { error: "forbidden" as const };
  if (send.status !== "scheduled") return { error: "already_sent" as const };

  const updateFields: Record<string, unknown> = {};
  if (updates.scheduledAt) updateFields.scheduled_at = updates.scheduledAt;
  if (updates.recipientPhone) updateFields.recipient_phone = updates.recipientPhone;

  const { data, error } = await supabase
    .from("card_sends")
    .update(updateFields)
    .eq("id", sendId)
    .select()
    .single();

  if (error) throw error;
  return { data };
}

export async function cancelSend(supabase: SupabaseClient, sendId: string, senderId: string) {
  const send = await getSendById(supabase, sendId);
  if (!send) return { error: "not_found" as const };
  if (send.sender_id !== senderId) return { error: "forbidden" as const };
  if (send.status !== "scheduled") return { error: "already_sent" as const };

  const { error } = await supabase.from("card_sends").delete().eq("id", sendId);

  if (error) throw error;
  return { success: true };
}

export async function updateSendGroup(
  supabase: SupabaseClient,
  sendGroupId: string,
  senderId: string,
  scheduledAt: string,
) {
  const { data: sends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (fetchError) throw fetchError;
  if (!sends || sends.length === 0) return { error: "not_found" as const };

  const { data, error } = await supabase
    .from("card_sends")
    .update({ scheduled_at: scheduledAt })
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled")
    .select();

  if (error) throw error;
  return { data };
}

export async function cancelSendGroup(
  supabase: SupabaseClient,
  sendGroupId: string,
  senderId: string,
) {
  const { data: sends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (fetchError) throw fetchError;
  if (!sends || sends.length === 0) return { error: "not_found" as const };

  const { error } = await supabase
    .from("card_sends")
    .delete()
    .eq("send_group_id", sendGroupId)
    .eq("sender_id", senderId)
    .eq("status", "scheduled");

  if (error) throw error;
  return { success: true };
}

export async function processScheduledSends(supabase: SupabaseClient, config: SendsWorkerConfig) {
  const { data: dueSends, error: fetchError } = await supabase
    .from("card_sends")
    .select("*")
    .eq("status", "scheduled")
    .lte("scheduled_at", new Date().toISOString());

  if (fetchError) throw fetchError;
  if (!dueSends || dueSends.length === 0) return [];

  const processed = [];

  for (const send of dueSends) {
    // 1. Send SMS via Twilio
    const { data: sender } = await supabase
      .from("users")
      .select("first_name")
      .eq("id", send.sender_id)
      .single();

    const senderFirstName = sender?.first_name ?? "Noen";
    const cardViewUrl = `${config.appBaseUrl}/s/${send.id}`;
    const result = await sendCardSms(
      config.twilio,
      send.recipient_phone,
      senderFirstName,
      cardViewUrl,
    );

    // 2. If SMS fails, log error and continue
    if (!result.success) {
      console.error(`[scheduled-sends] SMS failed for send ${send.id}: ${result.error}`);
      continue;
    }

    // 3. Mark card_send as sent
    const { error: updateError } = await supabase
      .from("card_sends")
      .update({ status: "sent", sent_at: new Date().toISOString() })
      .eq("id", send.id);

    if (updateError) continue;

    processed.push(send.id);
  }

  return processed;
}
