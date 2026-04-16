import { type SupabaseClient } from "@supabase/supabase-js";
import { findOrCreateUserByPhone } from "./users.service.js";
import { sendCardSms, type TwilioConfig } from "./notifications.service.js";

export interface SendsWorkerConfig {
  twilio: TwilioConfig;
  appBaseUrl: string;
}

export async function sendCard(
  supabase: SupabaseClient,
  senderId: string,
  cardId: string,
  options: { recipientPhone: string; scheduledAt?: string },
) {
  const { recipientPhone, scheduledAt } = options;

  // Resolve recipient (created eagerly so recipient_id is always populated)
  const { user: recipient } = await findOrCreateUserByPhone(supabase, recipientPhone);

  // Create the card_send record (always "scheduled" — the worker moves it to "sent")
  const { data: send, error: sendError } = await supabase
    .from("card_sends")
    .insert({
      card_id: cardId,
      sender_id: senderId,
      recipient_id: recipient.id,
      recipient_phone: recipientPhone,
      status: "scheduled",
      scheduled_at: scheduledAt ?? new Date().toISOString(),
      sent_at: null,
    })
    .select()
    .single();

  if (sendError) throw sendError;

  return send;
}

export async function getMySends(supabase: SupabaseClient, userId: string) {
  const { data, error } = await supabase
    .from("card_sends")
    .select("*")
    .or(`sender_id.eq.${userId},recipient_id.eq.${userId}`)
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
